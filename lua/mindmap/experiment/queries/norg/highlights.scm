;extends
(
  (paragraph_segment
    (inline_comment) @id
    (#match? @id "^.[0-9]\{8\}.$")
    (#set! @id conceal "※")
    (#set! @id priority "300")
  )
)
