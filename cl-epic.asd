(asdf:defsystem :cl-epic
  :author "Ben Diedrich"
  :license "MIT"
  :description "Generate videos of Earth from NASA's DSCOVR EPIC website"
  :depends-on ("drakma" "cl-html5-parser" "optima" "uiop")
  :serial t
  :components
  ((:file "epic")))
