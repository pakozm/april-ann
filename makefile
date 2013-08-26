ALL: release-mkl

document:
	lua build_release.lua document

test-macosx:
	lua build_debug_macosx.lua test

test-mkl:
	lua build_mkl_debug.lua test

#test:
#	lua build_debug.lua test

#test-cuda-mkl:
#	lua build_cuda_and_mkl_debug.lua test

release-macosx:
	lua build_release_macosx.lua

release-mkl:
	lua build_mkl_release.lua

release:
	lua build_release.lua

release-cuda-mkl:
	lua build_cuda_and_mkl_release.lua

debug-macosx:
	lua build_debug_macosx.lua

debug-mkl:
	lua build_mkl_debug.lua

debug:
	lua build_debug.lua

debug-cuda-mkl:
	lua build_cuda_and_mkl_debug.lua
