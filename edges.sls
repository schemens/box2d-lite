
(library (box2d-lite edges)

  (export make-edges

	  edges-in-edge-1
	  edges-out-edge-1
	  edges-in-edge-2
	  edges-out-edge-2

	  edges-in-edge-1-set!
	  edges-out-edge-1-set!
	  edges-in-edge-2-set!
	  edges-out-edge-2-set!

	  is-edges
	  import-edges

	  create-edges

	  edges-equal?

	  flip)

  (import (rnrs)
	  (box2d-lite util define-record-type)
	  (box2d-lite edge-numbers))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define-record-type++ edges
    is-edges
    import-edges
    (fields (mutable in-edge-1)
	    (mutable out-edge-1)
	    (mutable in-edge-2)
	    (mutable out-edge-2))
    (methods))

  (define (create-edges)
    (make-edges NO-EDGE NO-EDGE NO-EDGE NO-EDGE))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (edges-equal? a b)

    (is-edges a)
    (is-edges b)

    (and (equal? a.in-edge-1  b.in-edge-1)
	 (equal? a.out-edge-1 b.out-edge-1)
	 (equal? a.in-edge-2  b.in-edge-2)
	 (equal? a.out-edge-2 b.out-edge-2)))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (flip e)

    (is-edges e)

    (let ((tmp e.in-edge-1))

      (e.in-edge-1! e.in-edge-2)

      (e.in-edge-2! tmp))

    (let ((tmp e.out-edge-1))

      (e.out-edge-1! e.out-edge-2)

      (e.out-edge-2! tmp)))

  ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  )