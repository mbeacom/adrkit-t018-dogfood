<!-- @adr 0003 -->

# Markdown introducer fixture

Markdown gets its own, much smaller introducer set, and this file pins both
halves of that rule.

The HTML comment at the top of this file **does** declare `0003`, because an
HTML comment is the one thing markdown genuinely hides from its own output.

None of the lines below declares anything, even though every one of them would
be a comment in some source language:

# @adr 0001

`#` opens a heading here. Lending markdown the source-language introducer set is
what allowed a line a reader can plainly see to declare a decision, which is the
same defect class as a fenced example.

* @adr 0004

`*` opens a list item.

-- @adr 0006

`--` is a SQL comment, not a markdown one.

% @adr 0007

`%` is a TeX comment.

; @adr 0008

`;` is a Lisp comment.

Fenced examples are skipped here exactly as they are in source files:

```
<!-- @adr 0009 -->
```

Expected declaration set for this file: exactly `0003`. Asserted as `NEG-3` and
`POS-8` in scripts/validate-markers.sh.
