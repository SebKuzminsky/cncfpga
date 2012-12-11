; Copyright 2009 by Bdale Garbee <bdale@gag.com>
; gnet-partslistgag.scm
;
; derived from gnet-partslist3.scm 
; Copyright (C) 2001 MIYAMOTO Takanori
; 
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA

; The /'s may not work on win32

; Copyright (C) 2001 MIYAMOTO Takanori
; gnet-partslist-common.scm
; 
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA

(define (get-parts-table packages)
  (if (null? packages)
      '()
      (let ((package (car packages)))
	(if (string=? "1" (gnetlist:get-package-attribute package "nobom"))
	    (get-parts-table (cdr packages))
	    (cons (list (gnetlist:get-package-attribute package "refdes")
			(get-device package)
			(get-value package)  
			(gnetlist:get-package-attribute package "footprint")
			(gnetlist:get-package-attribute package "loadstatus")
			(gnetlist:get-package-attribute package "vendor")
			(gnetlist:get-package-attribute package "vendor_part_number")) ;; sdb change
		  (get-parts-table (cdr packages)))))))

(define (write-one-row ls separator end-char port)
  (if (null? ls)
      '()
      (begin (display "\"" port)
	     (display (car ls) port)
	     (for-each (lambda (st) (display separator port)(display st port)) (cdr ls))
	     (display end-char port))))

(define (get-sortkey-value ls key-column)
  (list-ref (car ls) key-column))

(define (marge-sort-sub ls1 ls2 key-column)
  (if (or (null? ls1) (null? ls2))
      (append ls1 ls2)
      (if (string-ci<=? (get-sortkey-value ls1  key-column) (get-sortkey-value ls2 key-column))
	  (cons (car ls1) (marge-sort-sub (cdr ls1) ls2 key-column))
	  (cons (car ls2) (marge-sort-sub ls1 (cdr ls2) key-column)))))

(define (marge-sort ls key-column)
  (let ((midpoint (inexact->exact (floor (/ (length ls) 2)))))
    (if (<= (length ls) 1)
	(append ls)
	(let ((top-half (reverse (list-tail (reverse ls) midpoint)))
	      (bottom-half (list-tail ls (- (length ls) midpoint))))
	  (set! top-half (marge-sort top-half key-column))
	  (set! bottom-half (marge-sort bottom-half key-column))
	  (marge-sort-sub top-half bottom-half key-column)))))

(define (marge-sort-with-multikey ls key-columns)
  (if (or (<= (length ls) 1) (null? key-columns))
      (append ls)
      (let* ((key-column (car key-columns))
	     (sorted-ls (marge-sort ls key-column))
	     (key-column-only-ls 
	      ((lambda (ls) (let loop ((l ls))
			      (if (null? l)
				  '()
				  (cons (get-sortkey-value l key-column) (loop (cdr l))))))
	       sorted-ls))
	     (first-value (get-sortkey-value sorted-ls key-column))
	     (match-length (length (member first-value (reverse key-column-only-ls))))
	     (first-ls (list-tail (reverse sorted-ls) (- (length sorted-ls) match-length)))
	     (rest-ls (list-tail sorted-ls match-length)))
	(append (marge-sort-with-multikey first-ls (cdr key-columns))
		(marge-sort-with-multikey rest-ls key-columns)))))

(define partslistgag:write-top-header
  (lambda (port)
    (display "\"device\",\"value\",\"footprint\",\"loadstatus\",\"vendor\",\"vendor_part_number\",\"quantity\",\"refdes\"\n" port)))

(define (partslistgag:write-partslist ls port)
  (if (null? ls)
      '()
      (begin (write-one-row (cdar ls) "\",\"" "\"," port)
	     (write-one-row (caar ls) " " "\"\n" port)
	     (partslistgag:write-partslist (cdr ls) port))))

(define partslistgag:write-bottom-footer
  (lambda (port)
      '()
    ))

(define (count-same-parts ls)
  (if (null? ls)
      (append ls)
      (let* ((parts-table-no-uref (let ((result '()))
				    (for-each (lambda (l) (set! result (cons (cdr l) result))) (reverse ls))
				    (append result)))
	     (first-ls (car parts-table-no-uref))
	     (match-length (length (member first-ls (reverse parts-table-no-uref))))
	     (rest-ls (list-tail ls match-length))
	     (match-ls (list-tail (reverse ls) (- (length ls) match-length)))
	     (uref-ls (let ((result '()))
			(for-each (lambda (l) (set! result (cons (car l) result))) match-ls)
			(append result))))
	(cons (cons uref-ls (append first-ls  (list match-length))) (count-same-parts rest-ls)))))

(define partslistgag
  (lambda (output-filename)
    (let ((port (open-output-file output-filename))
	  (parts-table (marge-sort-with-multikey (get-parts-table packages) '(1 2 3 0))))
      (set! parts-table (count-same-parts parts-table))
      (partslistgag:write-top-header port)
      (partslistgag:write-partslist parts-table port)
      (partslistgag:write-bottom-footer port)
      (close-output-port port))))
