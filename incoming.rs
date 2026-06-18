#!/usr/bin/env -S cargo +nightly -Zscript
---
[package]
edition = "2024"
[dependencies]
ureq = { version = "3.0.2", features = ["json"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
dialoguer = { version = "0.11", features = ["fuzzy-select"] }
unicode-normalization = "0.1"
unidecode = "0.3"
clap = { version = "4.4", features = ["derive"] }
---

use clap::Parser;
use std::process::{Command, ExitStatus, Stdio};

const REMOTE: &str = "incoming@incoming-ro.asterix.cz:/home/incoming";
const PORT: &str = "2244";
const SITES_URL: &str = "https://atxupdater:AtxUpdater911@dbs.asterix.cz/sites";

#[derive(Debug, serde::Deserialize)]
struct Site {
    id: String,
    company: Option<String>,
    place: Option<String>,
    active: Option<String>,
    id_zapa: Option<String>,
}

#[derive(Parser, Debug)]
#[command(name = "get")]
#[command(about = "Get and sync site data")]
struct Args {
    #[arg(short = 'r', long, help = "Run rotate and sync before getting data")]
    rotate_and_sync: bool,
    #[arg(short = 'n', long, help = "Do not actually sync")]
    no_sync: bool,
    #[arg(short = 'a', long, help = "Activate after download")]
    activate: bool,
    #[arg(help = "Site IDs to process")]
    sites: Vec<String>,
}

// so i can just type f! instead of format!
macro_rules! f { ($($arg:tt)*) => (format!($($arg)*)); }

fn remove_diacritics(text: &str) -> String {
    unidecode::unidecode(text)
}

fn fetch_sites() -> Vec<Site> {
    let mut response = ureq::get(SITES_URL).call().unwrap();
    response.body_mut().read_json().unwrap()
}

fn select_site(sites: &[Site]) -> String {
    let items: Vec<String> = sites
        .iter()
        .map(|site| {
            let text = format!(
                "{} {} {} active={} id_zapa={}",
                site.id,
                site.company.clone().unwrap_or_default(),
                site.place.clone().unwrap_or_default(),
                site.active.clone().unwrap_or_default(),
                site.id_zapa.clone().unwrap_or_default()
            );
            remove_diacritics(&text)
        })
        .collect();
    let selection = dialoguer::FuzzySelect::new()
        .with_prompt("Select a site:")
        .items(&items)
        .interact()
        .unwrap();
    sites[selection].id.clone()
}

//fn r(c: String) -> anyhow::Result<ExitStatus> {
fn r(c: &str) -> ExitStatus {
    println!("+ {c}");
    //return Ok(Command::new("/usr/bin/bash").arg("-c").arg(c).status()?);
    return Command::new("/usr/bin/bash")
        .arg("-c")
        .arg(c)
        .status()
        .unwrap();
}

fn o(c: &str) -> String {
    let x = Command::new("/usr/bin/bash")
        .arg("-c")
        .arg(c)
        .stderr(Stdio::inherit())
        .output()
        .unwrap()
        .stdout;
    String::from_utf8(x).unwrap()
}

fn rotate_and_sync(mj: &str) {
    let cmd = f!("omnirun remoteadmin:Atx43872298@{mj}.asterix.cz -X --script https://raw.githubusercontent.com/rpodgorny/bootstrap/master/rotate_and_sync.sh");
    r(&cmd);
}

fn sync(mj: &str, dest: &str) {
    //let rsync = "rsync -avP --timeout=20";
    //let rsync = "rsync -azz --info=progress2,stats --timeout=20";
    let rsync = "rsync -azz --info=progress2 --timeout=20";

    r(&f!("mkdir -p {dest}/{mj}/atx300/control/data"));
    r(&f!("{rsync} {REMOTE}/{mj}/atx300/control/data/info.txt {dest}/{mj}/atx300/control/data/ --delete-after || true"));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/atx300/log/control.log {dest}/{mj}/atx300/log/ --delete-after || true"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/atx300/log {dest}/{mj}/atx300/ --delete-after"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/atx300/*.mem {dest}/{mj}/atx300/ --delete-after"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/atx300/set {dest}/{mj}/atx300/ --delete-after"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/atx300/conf {dest}/{mj}/atx300/ --delete-after"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/atx300/param/data {dest}/{mj}/atx300/param/ --delete-after"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/atx300/comm {dest}/{mj}/atx300/ --delete-after"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/atx300/data {dest}/{mj}/atx300/ --delete-after || true"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/atx300/minidisp {dest}/{mj}/atx300/ --delete-after || true"
    ));
    r(&f!("mkdir -p {dest}/{mj}/atx300/visual"));
    r(&f!("{rsync} {REMOTE}/{mj}/atx300/visual/data {dest}/{mj}/atx300/visual/ --exclude=data/log.txt --delete-after || true"));
    r(&f!("mkdir -p {dest}/{mj}/atx300/history"));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/history/comm {dest}/{mj}/history/ --delete-after || true"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/history/log {dest}/{mj}/history/ --delete-after || true"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj}/history/signals {dest}/{mj}/history/ --delete-after || true"
    ));

    r(&f!("{rsync} {REMOTE}/{mj} {dest}/ --exclude={mj}/atx300/Backup_DBW --exclude={mj}/archive --exclude={mj}/history --exclude={mj}/atx300/log || true"));
    r(&f!(
        "{rsync} {REMOTE}/{mj} {dest}/ --exclude={mj}/archive --exclude={mj}/history || true"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj} {dest}/ --exclude={mj}/archive --exclude={mj}/history/signals || true"
    ));
    r(&f!(
        "{rsync} {REMOTE}/{mj} {dest}/ --exclude={mj}/archive || true"
    ));
    r(&f!("{rsync} {REMOTE}/{mj} {dest}/"));
    //r(&f!("{rsync} {REMOTE}/{mj} {dest}/ --delete-after"));
}

fn main() {
    let args = Args::parse();

    let mut mjs = if args.sites.is_empty() {
        let sites = fetch_sites();
        let selected_id = select_site(&sites);
        vec![selected_id]
    } else {
        args.sites
    };

    // TODO: do this in parallel
    if args.rotate_and_sync {
        for mj in &mjs {
            rotate_and_sync(mj);
        }
    }

    let dest = "/home/radek/tmp/incoming";

    if !args.no_sync {
        unsafe {
            std::env::set_var("RSYNC_RSH", f!("ssh -p {PORT}"));
        }

        for mj in mjs.iter() {
            sync(mj, dest);
        }
    }

    let mj = mjs[mjs.len() - 1].clone();
    let activate = if args.activate {
        true
    } else {
        println!("activate {mj}?");
        let mut line = String::new();
        let _ = std::io::stdin().read_line(&mut line).unwrap();
        line.starts_with("y")
    };
    if activate {
        r(&f!("ln -sf {dest}/{mj}/atx300 /home/radek/"));
        r(&f!("ln -sf {dest}/{mj} /home/radek/atx300/_incoming"));
    }
    //Ok(())
}
