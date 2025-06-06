if tup.getconfig("NO_FASM") ~= "" then return end
HELPERDIR = (tup.getconfig("HELPERDIR") == "") and "../../../programs" or tup.getconfig("HELPERDIR")
tup.include(HELPERDIR .. "/use_fasm.lua")
add_include(tup.getvariantdir())

tup.rule("default.dtp.asm", 'fasm "%f" "%o"', "default.dtp")
tup.rule({"8Metro.asm", extra_inputs = {"default.dtp"}}, FASM .. ' "%f" "%o" ' .. tup.getconfig("KPACK_CMD"), "8Metro.skn")
