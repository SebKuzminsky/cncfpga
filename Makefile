# intentionally want to rebuild drc and bom on every invocation
all:	drc partslist partslist.csv pcb

drc:	cncfpga.sch Makefile
	-gnetlist -g drc2 cncfpga.sch -o cncfpga.drc

partslist:	cncfpga.sch Makefile
	gnetlist -g bom -o cncfpga.unsorted cncfpga.sch
	head -n1 cncfpga.unsorted > partslist
	tail -n+2 cncfpga.unsorted | sort >> partslist
	rm -f cncfpga.unsorted

partslist.csv:	cncfpga.sch Makefile
	gnetlist -m scheme/gnet-partslistgag.scm -g partslistgag \
		-o cncfpga.unsorted cncfpga.sch
	head -n1 cncfpga.unsorted > partslist.csv
	tail -n+2 cncfpga.unsorted | sort -t \, -k 8 >> partslist.csv
	rm -f cncfpga.unsorted

pcb:	cncfpga.sch project Makefile
	gsch2pcb project

cncfpga.xy:	cncfpga.pcb
	pcb -x bom cncfpga.pcb

cncfpga.bottom.gbr:	cncfpga.pcb
	pcb -x gerber cncfpga.pcb

zip:	cncfpga.bottom.gbr cncfpga.bottommask.gbr cncfpga.fab.gbr cncfpga.top.gbr cncfpga.topmask.gbr cncfpga.toppaste.gbr cncfpga.topsilk.gbr cncfpga.group2.gbr cncfpga.group3.gbr cncfpga.plated-drill.cnc cncfpga.xy  Makefile # cncfpga.xls
	zip cncfpga.zip cncfpga.*.gbr cncfpga.*.cnc cncfpga.xy # cncfpga.xls

clean:
	rm -f *.bom *.drc *.log *~ cncfpga.ps *.gbr *.cnc *bak* *- *.zip 
	rm -f *.net *.xy *.cmd *.png partslist partslist.csv
	rm -f *.partslist *.new.pcb *.unsorted cncfpga.xls

