\include "../make-grobs.ily"

%%%
%%% Grob properties
%%%

#(define-grob-property 'top-space number? "The amount of space at the top of the grid")
#(define-grob-property 'grid-space number? "The amount of space between each gridline")
#(define-grob-property 'overshoot number? "The length that a grid gets extended")

%%%
%%% Grob routines
%%%							     

#(define (tab-duration::print me)
  (cond 
   ((getOption '(lily-lute tab-duration useFlags))
     (flag-style me))
   ((getOption '(lily-lute tab-duration useNoteHeads))
     (note-head-style me))))

#(define (note-head-style me)
  (let* ((mol           '())
         (grob-markup   '())
         (durlog         (- (ly:grob-property me 'duration-log) 1))
         (dots           (ly:grob-object me 'dots))
         (dot-count      0)
         (font-size      (ly:grob-property me 'font-size))
         (left-padding   (ly:grob-property me 'left-padding))
         (right-padding  (ly:grob-property me 'right-padding))
         (staff-padding  (ly:grob-property me 'staff-padding)))

  (if (not (null? dots))
   (set! dot-count (ly:grob-property dots 'dot-count)))

  (set! grob-markup (grob-interpret-markup me
                     (markup #:fontsize font-size
                              #:hspace left-padding
                              #:note-by-number durlog dot-count UP
                              #:hspace right-padding
                              #:vspace staff-padding)))

  (set! mol (ly:make-stencil (ly:stencil-expr grob-markup) '(0 . 0) '(0 . 0)))

  mol))

#(define (flag-style me)
  (let* ((y1            (ly:grob-property me 'stem-begin-position))
	 (y2            (+ (ly:grob-property me 'length) y1))
	 (half-space    (* (ly:staff-symbol-staff-space me) 0.5))
	 (stem-y        (cons (* (min y1 y2) half-space) (* (max y2 y1) half-space)))
	 (stem-width    (* (ly:staff-symbol-line-thickness me) (ly:grob-property me 'thickness)))
	 (blot          (ly:output-def-lookup (ly:grob-layout me) 'blot-diameter))
	 (padding-x     (car (ly:grob-property me 'flag-padding)))
	 (padding-y     (cdr (ly:grob-property me 'flag-padding)))
	 (mol           (ly:round-filled-box (cons (* padding-x -1)
					      (- stem-width padding-x)) stem-y blot))
	 (print-flag?   (ly:grob-object me 'print-flag?))
	 (flag          (ly:grob-object me 'flag))
	 (fs            (ly:grob-property flag 'stencil))
	 (dots          (ly:grob-object me 'dots))
	 (dot-count     0)
	 (radius        (ly:grob-property me 'dot-radius))
	 (dot-pos       (ly:grob-property me 'dot-position))
	 (separation    (ly:grob-property me 'dot-separation)))

   (begin
    (if print-flag?
     (begin
      (if (not (null? dots))
       (begin
	(set! dot-count (ly:grob-property dots 'dot-count))
	(set! dots (ly:round-filled-box (cons 0 radius) (cons 0 radius) 1))

	(if (> dot-count 1)
	 (set! dots (add-dots (- dot-count 1) dots radius separation)))

	(set! dots (ly:stencil-aligned-to dots X 
		    (* (- (car dot-pos) (* dot-count half-space)) -1)))

	(set! fs (ly:stencil-combine-at-edge fs Y DOWN dots (cdr dot-pos)))))

      (set! mol (ly:stencil-combine-at-edge mol Y UP fs (+ (car (ly:stencil-extent fs Y)) 
							 padding-y)))))    
    
    (ly:grob-suicide! flag)

    mol)))

#(define (add-dots i dots radius separation)
  (let   ((new-dots (ly:round-filled-box (cons 0 radius) (cons 0 radius) 1)))
   (if (= i 0) dots
    (begin
     (set! new-dots (ly:stencil-combine-at-edge dots X RIGHT new-dots dotSep))
     (add-dots (- i 1) new-dots radius)))))

#(define (tab-duration::calc-x-offset me)
  (if (not (null? (ly:grob-object me 'note-head-extent)))
   (+ (/ (ly:grob-object me 'note-head-extent) 2)
    (car (ly:grob-property me 'flag-padding)))))

%%%
%%% Grob descriptions
%%%

#(add-grob-definition 'TabDuration
  `(
    (stencil . ,tab-duration::print)
    (Y-extent . ,grob::always-Y-extent-from-stencil)
    (X-offset . ,tab-duration::calc-x-offset)
    (stem-begin-position . 0.0)
    (length . 6.0)
    (side-axis . ,Y)
    (dot-radius . 0.4)
    (dot-position . (4 . 0.5))
    (dot-separation . 0.5)
    (thickness . 2.0)
    (font-size . -1)
    (left-padding . -0.5)
    (right-padding . 0)
    (direction . ,UP)
    (self-alignment-X . ,CENTER)
    (extra-spacing-width . (-1 . 1))
    (outside-staff-horizontal-padding . 0.1)
    (staff-padding . 1.75)
    (flag-padding . (0.15 . -0.025))
    (outside-staff-priority . 750)
    (X-align-on-main-noteheads . #t)
    (vertical-skylines . ,grob::always-vertical-skylines-from-stencil)
    (duration-log . ,stem::calc-duration-log)
    (meta . ((class . Item)
	     (interfaces . (staff-symbol-referencer-interface
			    side-position-interface
			    self-alignment-interface
			    rhythmic-grob-interface
			    rhythmic-head-interface))))))

#(add-grob-definition 'TabGrid
  `(
    (after-line-breaking . ,ly:spanner::kill-zero-spanned-time)
    (bound-details . ((left . ((Y . 0)
			       (padding . 0.0)
			       (attach-dir . ,LEFT)
			       (overshoot . 0.4)
			     ))
		      (right . ((Y . 0)
				(padding . 0.0)
				(attach-dir . ,RIGHT)
				(overshoot . 0.4)
			      ))
		    ))
    (staff-padding . 0.8)
    (left-bound-info . ,ly:line-spanner::calc-left-bound-info)
    (normalized-endpoints . ,ly:spanner::calc-normalized-endpoints)
    (right-bound-info . ,ly:line-spanner::calc-right-bound-info)
    (thickness . 2.5)
    ;; (extra-spacing-width . (-0.5 . 0.5))
    (top-space . 1.0)
    (grid-space . 1.0)
    (stencil . ,ly:line-spanner::print)
    (style . line)
    (vertical-skylines . ,grob::unpure-vertical-skylines-from-stencil)
    (X-extent . #f)
    (Y-extent . #f)
    (meta . ((class . Spanner)
	     (interfaces . (line-interface
			    line-spanner-interface
			    outside-staff-interface
			    self-alignment-interface
			    unbreakable-spanner-interface))))))

