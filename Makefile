# intentionally want to rebuild drc and bom on every invocation
all:	drc partslist partslist.csv pcb

drc:	cnc4pga.sch Makefile
	-gnetlist -g drc2 cnc4pga.sch -o cnc4pga.drc

partslist:	cnc4pga.sch Makefile
	gnetlist -g bom -o cnc4pga.unsorted cnc4pga.sch
	head -n1 cnc4pga.unsorted > partslist
	tail -n+2 cnc4pga.unsorted | sort >> partslist
	rm -f cnc4pga.unsorted

partslist.csv:	cnc4pga.sch Makefile
	gnetlist -g partslistgag -o cnc4pga.unsorted cnc4pga.sch
	head -n1 cnc4pga.unsorted > partslist.csv
	tail -n+2 cnc4pga.unsorted | sort -t \, -k 8 >> partslist.csv
	rm -f cnc4pga.unsorted

pcb:	cnc4pga.sch project Makefile
	gsch2pcb project

cnc4pga.xy:	cnc4pga.pcb
	pcb -x bom cnc4pga.pcb

cnc4pga.bottom.gbr:	cnc4pga.pcb
	pcb -x gerber cnc4pga.pcb

zip:	cnc4pga.bottom.gbr cnc4pga.bottommask.gbr cnc4pga.fab.gbr cnc4pga.top.gbr cnc4pga.topmask.gbr cnc4pga.toppaste.gbr cnc4pga.topsilk.gbr cnc4pga.group2.gbr cnc4pga.group3.gbr cnc4pga.plated-drill.cnc cnc4pga.xy  Makefile # cnc4pga.xls
	zip cnc4pga.zip cnc4pga.*.gbr cnc4pga.*.cnc cnc4pga.xy # cnc4pga.xls

clean:
	rm -f *.bom *.drc *.log *~ cnc4pga.ps *.gbr *.cnc *bak* *- *.zip 
	rm -f *.net *.xy *.cmd *.png partslist partslist.csv
	rm -f *.partslist *.new.pcb *.unsorted cnc4pga.xls

