unit Custom.Button.Image;

interface

const
  cImage =
'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';
implementation

end.
