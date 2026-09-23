-- Packaging fixture: tools/test-package checks this debug block is stripped.
local _, ns = ...
--@debug@
ns.debugOnly = true
--@end-debug@
ns.shipped = true
