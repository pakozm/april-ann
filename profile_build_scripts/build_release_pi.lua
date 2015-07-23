dofile("luapkg/formiga.lua")
local postprocess = dofile("profile_build_scripts/postprocess.lua")
formiga.build_dir = "build_release_pi"

local packages = dofile "profile_build_scripts/package_list.pi.lua"
-- table.insert(packages, "rlcompleter") -- AUTOCOMPLETION => needs READLINE

luapkg{
  program_name = "april-ann",
  verbosity_level = 0,  -- 0 => NONE, 1 => ONLY TARGETS, 2 => ALL
  packages = packages,
  version_flags = dofile "profile_build_scripts/VERSION.lua",
  disclaimer_strings = dofile "profile_build_scripts/DISCLAIMER.lua",
  global_flags = {
    debug="no",
    use_lstrip = "yes",
    use_readline="yes",
    optimization = "yes",
    platform = "unix",
    extra_flags={
      "-DNDEBUG",
      "-DNO_POOL",
      "-DNO_OMP",
      "-DNO_MM_MALLOC",
      "-fPIC",
    },
    extra_libs={
      "-fPIC",
      "-lpthread",
      "-lblas",
      "-lcblas",
      "-latlas",
      "-rdynamic",
      "-llapack_atlas",
      "-llapacke",
    },
    shared_extra_libs={
      "-shared",
      "-llua5.2",
      "-I/usr/include/lua5.2",
    },
  },
  
  main_package = package{
    name = "main_package",
    default_target = "build",
    target{
      name = "init",
      mkdir{ dir = "bin" },
      mkdir{ dir = "build" },
      mkdir{ dir = "include" },
    },
    target{
      name = "provide",
      depends = "init",
      copy{ file = formiga.os.compose_dir(formiga.os.cwd,"lua","include","*.h"), dest_dir = "include" }
    },
    target{ name = "clean_all",
      exec{ command = [[find . -name "*~" -exec rm {} ';']] },
      delete{ dir = "bin" },
      delete{ dir = "build" },
      delete{ dir = "build_doc" },
      delete{ dir = "doxygen_doc" },
    },
    target{ name = "clean",
      delete{ dir = "bin" },
      delete{ dir = "build" },
      delete{ dir = "build_doc" },
    },
    target{ name = "document_clean",
      delete{ dir = "build_doc" },
      delete{ dir = "doxygen_doc" },
    },
    target{
      name = "build",
      depends = "provide",
      compile_luapkg_utils{},
      link_main_program{},
      create_static_library{},
      create_shared_library{},
      copy_header_files{},
      dot_graph{
	file_name = "dep_graph.dot"
      },
      use_timestamp = true,
    },
    target{
      name = "test",
      depends = "build",
    },
    target{ name = "document",
      echo{"this is documentation"},
      main_documentation{
	dev_documentation = {
	  main_documentation_file = formiga.os.compose_dir("docs","april_dev.dox"),
	  doxygen_options = {
	    GENERATE_LATEX  = 'NO',
	  },
	},
	user_documentation = {
	  main_documentation_file = formiga.os.compose_dir("docs","april_user_ref.dox"),
	  doxygen_options = {
	    GENERATE_LATEX = 'NO',
	  },
	}
      },
    },
  },
}

postprocess(arg, formiga)
