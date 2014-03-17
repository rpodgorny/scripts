for i in `ls *.jpg`; do
	echo $i
	convert $i -auto-orient auto_$i
	mv auto_$i $i
done
