" Title: SpringBoot-Start Plugin
" Description: SpringBoot start plugin
" Maintainer: niT-Tin https://github.com/niT-Tin


" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.

let s:true = 1
let s:false = 0

if exists("g:loaded_springboot_start")
  finish
endif

let g:loaded_springboot_start = s:true

" let s:home = expand("$HOME")
" let s:home = substitute(s:home, '\', '/', 'g')
" let s:plugin_root_folder = substitute(expand("<sfile>:p:h:h"), '\', '/', 'g')

" Plugin Commands {{{

    :command! -nargs=0 SpringBootStartMenu lua require('springboot-start.init').menu()

    :command! -nargs=0 SpringBootGetDep lua require('springboot-start.init').getdep()
    :command! -nargs=0 SpringBootGetProjectType lua require('springboot-start.init').gettype()
    :command! -nargs=0 SpringBootGetParam lua require('springboot-start.init').getpara()
    :command! -nargs=0 SpringBootChoseDir lua require('springboot-start.init').chose_dir()

    :command! -nargs=0 SpringBootShowDep lua require('springboot-start.init').show_dep()
    :command! -nargs=0 SpringBootShowProjectType lua require('springboot-start.init').show_rel()
    :command! -nargs=0 SpringBootShowParam lua require('springboot-start.init').show_para()
    :command! -nargs=0 SpringBootShowSelected lua require('springboot-start.init').show_selected()

    :command! -nargs=0 SpringBootCreate lua require('springboot-start.init').create_project()
    " :command! -nargs=0 SpringBootInit lua require('springboot-start.init').init()
    :command! -nargs=0 SpringBootRemoveCache lua require('springboot-start.init').remove_cache()
    :command! -nargs=0 SpringBootUpdateCache lua require('springboot-start.init').update_cache()

    :command! -nargs=0 SpringBootShowLast lua require('springboot-start.init').show_last_selected()
    :command! -nargs=0 SpringBootCreateLast lua require('springboot-start.init').create_last()
    :command! -nargs=0 SpringBootGetLast lua require('springboot-start.init').get_last()
    :command! -nargs=0 SpringBootDeleteDep lua require('springboot-start.init').delete_dep()
    :command! -nargs=0 SpringBootCacheDir lua require('springboot-start.init').cache_dir()

" }}}
