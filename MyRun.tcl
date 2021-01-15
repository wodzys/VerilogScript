# --------------------------------------------------------------------------- #
# --- this is a .tcl file running for modelsim or questasim
# --- you can copy the command as below to run it :
# 
# --- do run.tcl
# --- tips:
#           use relative paths
#           Please modify before use
# 
# --- 文件结构
# ```
# **PrjName**
# ├─ HDL                      // rtl design files
# ├─ README.md                // 版本说明
# ├─ read_me.txt              // 修改说明
# └─ Simulation               // 仿真文件
#    ├─ modelsim              // 仿真工程
#    │  ├─ libraries
#    │  │  ├─ 220model.v
#    │  │  └─ altera_mf.v
#    │  ├─ MyRun.tcl          // run script
#    │  ├─ rtl_file_list.f    // rtl files list
#    │  ├─ run.tcl
#    │  ├─ wave.do            // 波形控制文件
#    ├─ testbench             // testbench files
#    └─ testbench_202010
# ```

# --------------------------------------------------------------------------- #
    echo ":: QuestaSim general compile script version 2.6"
    echo ":: Edit By SmartBai 2021, Beijing"
# --------------------------------------------------------------------------- #
    # --- project path
    quietly set quartus_prj_path "../.."
    quietly set sim_prj_path "."
    quietly set rtl_path "$quartus_prj_path/HDL"
    quietly set testbench_path "$quartus_prj_path/Simulation/testbench_202010"
    quietly set rtl_file_list_name "rtl_file_list"

    # testbench name without .v, .vt, vhd, .vht
    set testbench_name BTM_test_top

    # simulation time ; ns/us/ms/min
    # quietly set sim_time 100ns
    quietly set sim_time -all

    # you can select "altera", "lattice" or "anlogic" device
    quietly set device "altera"

    # default wave color :        rst      clk     en     cnt    data    flag    default
    quietly set default_color { "orange" "silver" "pink" "gold" "olive" "purple" "green" }

    # monitor resolution ratio , for example : 1920 x 1080
    # 小窗显示,手动最大化
    quietly set m_width 800
    quietly set m_height 600

# --------------------------------------------------------------------------- #
    # Compile out of date files
    if {[catch {set last_compile_time}] == 1} {
        puts "set last_compile_time 0"
        set last_compile_time 0
    }

# --------------------------------------------------------------------------- #
    # --- set simulation library path
    # --- altera
    quietly set altera_lib_path "D:/intelFPGA/18.0/quartus/eda/sim_lib"
    # --- anlogic
    quietly set anlogic_lib_path "D:/Anlogic/TD4.6.4/sim"

    # check the root directory of quartus
    if { [info exists ::env(QUARTUS_ROOTDIR)] } {
        # 将正斜杠 (/) 替换反斜杠 (\)
        quietly set quartus_rootdir [file normalize $::env(QUARTUS_ROOTDIR)]
        quietly set altera_lib_path $quartus_rootdir/eda/sim_lib
    }

    # add altera quartus simulation library
    namespace eval lib_ns {
        proc lattice_lib_list {} {
            set lib_name {}
            return $lib_name
        }

        proc anlogc_lib_list {} {
            set lib_name {}
            return $lib_name
        }

        proc altera_verilog_lib_list {} {
            set lib_name {}

            lappend lib_name 220model
            lappend lib_name altera_mf

            return $lib_name
        }

        proc altera_vhdl_lib_list {} {
            set lib_name {}
            return $lib_name
        }
    }

# --------------------------------------------------------------------------- #
    # --- Filelist Creat
    # 获取当前文件夹下的目录
    proc next_dir {cur_dir} { glob -nocomplain -directory $cur_dir -types d *}
    # 获取当前文件夹下的文件
    proc next_list {cur_dir} { glob -nocomplain -directory $cur_dir -types f *.v}

    # Find all files
    proc auto_list_create {cur_dir} {
        set file_path {}
        set _f1 [next_list $cur_dir]
        foreach item $_f1 {
            lappend file_path $item
        }
        set _d1 [next_dir $cur_dir]
        foreach i $_d1 {
            foreach item [auto_list_create $i] {
                lappend file_path $item
            }
        }
        return $file_path
    }

    proc create_file_list {} {
        global sim_prj_path rtl_path rtl_file_list_name
        set _lf1 [open $sim_prj_path/$rtl_file_list_name.f w]
        set _file_list [auto_list_create $rtl_path]
        set len_file_list [llength $_file_list]

        while {$len_file_list > 0} {
            foreach item $_file_list {
                if {[llength $item] > 0} {
                    puts $_lf1 $item
                }
            }
            break
        }
        
        close $_lf1
        echo "There are $len_file_list files in total."
        echo "Filelist Create Complete !!!"
    }

    # file list
    namespace eval ver_ns {
        proc rtl_file_list {} {
            global sim_prj_path rtl_file_list_name
            set new_content {}
            set fd [open $sim_prj_path/$rtl_file_list_name.f r]
            set old_content [read -nonewline $fd]
            close $fd

            foreach item $old_content {
                if {[regexp {bak} $item] == 0} {
                    lappend new_content $item
                }
            }
            return $new_content
        }

        proc test_file_list {} {
            set file_name {}

            lappend file_name report_pkg
            lappend file_name BTM_test_pkg
            lappend file_name test
            lappend file_name BTM_test_top

            return $file_name
        }
    }

# --------------------------------------------------------------------------- #
    # --- 添加仿真库
    proc add_lib {} {
        global altera_lib_path lattice_lib_path device last_compile_time

        if {$device == "altera"} {
            foreach lib_name [lib_ns::altera_verilog_lib_list] {
                if {$last_compile_time < [file mtime $altera_lib_path/$lib_name.v]} {
                    vlog -incr -vlog01compat -work verilog_lib $altera_lib_path/$lib_name.v
                }
            }
        } else {
            foreach lib_path [lib_ns::lattice_lib_list] {
                set vfiles [glob -nocomplain -directory $lattice_lib_path/verilog/$lib_path *.v]
                foreach one_file $vfiles {
                    vlog -incr -work verilog_lib $one_file
                }
            }
        }
        
        # vlib vhdl_lib
        # vmap vhdl_lib vhdl_lib
        # if {$device == "altera"} {
        #     foreach lib_name [lib_ns::altera_vhdl_lib_list] {
        #         vcom -work vhdl_lib $altera_lib_path/$lib_name.vhd
        #     }
        # } else {
        #     # vcom -work vhdl_lib $lattice_lib_path/vhdl/MACH_Components.vhd
        #     foreach lib_path [lib_ns::lattice_lib_list] {
        #         set vhdfiles [glob -nocomplain -directory $lattice_lib_path/vhdl/$lib_path *.vhd]
        #         foreach one_file $vhdfiles {
        #             # their something wrong with diamond vhdl library
        #             # vcom -work vhdl_lib $one_file
        #         }
        #     }
        # }
        puts -nonewline "add "
        puts -nonewline $device
        puts " libraries successfully!"
    }

# --------------------------------------------------------------------------- #
    # --- 添加 RTL 文件和 testbench 文件
    proc add_file {} {
        global testbench_path last_compile_time

        foreach lib_name  [ver_ns::rtl_file_list] {
            if {$last_compile_time < [file mtime $lib_name]} {
                vlog -sv -work rtl_lib $lib_name
            }
        }

        foreach lib_name [ver_ns::test_file_list] {
            if {$last_compile_time < [file mtime $testbench_path/$lib_name.sv]} {
                vlog -sv -work test_lib $testbench_path/$lib_name.sv
            }
        }

        puts "add rtl and test files successfully!"
    }

# --------------------------------------------------------------------------- #
    # radix types : binary, ascii, unsigned, decimal, octal, hex, symbolic, time, and default
    proc wave_style_set {} {
        global testbench_name default_color
        foreach sig [find signals $testbench_name/*] {
            switch -regexp -nocase -- $sig {
                /*/*rst+     {add wave -radix binary     -color [lindex $default_color 0] $sig}
                /*/*clk+     {add wave -radix binary     -color [lindex $default_color 1] $sig}
                /*/*en+      {add wave -radix binary     -color [lindex $default_color 2] $sig}
                /*/*cnt+     {add wave -radix decimal    -color [lindex $default_color 3] $sig}
                /*/*data+    {add wave -radix hex        -color [lindex $default_color 4] $sig}
                /*/*flag+    {add wave -radix binary     -color [lindex $default_color 5] $sig}
                default      {add wave -radix hex        -color [lindex $default_color 6] $sig}
            }
        }
    }

# --------------------------------------------------------------------------- #
    proc run_all {} {
        global testbench_name sim_time m_height m_width sim_prj_path last_compile_time
        vlib verilog_lib
        vmap verilog_lib verilog_lib
        vlib rtl_lib
        vmap rtl_lib rtl_lib
        vlib test_lib
        vmap test_lib test_lib
        vlib work
        vmap work test_lib

        add_lib
        add_file

        # 编译完成后更新编译时间
        quietly set last_compile_time [clock seconds]

        quit -sim

        vsim -novopt -L verilog_lib -L rtl_lib work.$testbench_name
        if {[file exists $sim_prj_path/wave.do] == 1} {
            do $sim_prj_path/wave.do
        } else {
            wave_style_set
        }
        view structure
        view signals
        view -undock wave -x 0 -y 0 -width $m_width -height $m_height
        run $sim_time
        # wave zoom full
    }
    proc reload  {} {
        puts "re load tcl file"
        uplevel #0 source MyRun.tcl
    }
    proc re_run {} {
        global last_compile_time
        set last_compile_time 0
        run_all
    }
    proc quit_f  {} {
        quit -force
    }


    # proc clean_all {} {
    #     if {[file exists rtl_work]} {
    #         vdel -lib rtl_work -all
    #     }
    #     if {[file exists altera_mf_ver]} {
    #         vdel -lib altera_mf_ver -all
    #     }
    #     if {[file exists lpm_ver]} {
    #         vdel -lib lpm_ver -all
    #     }
    #     if {[file exists rtl_lib]} {
    #         vdel -lib rtl_lib -all
    #     }
    #     if {[file exists verilog_lib]} {
    #         vdel -lib verilog_lib -all
    #     }
    # }

    proc do_help {} {
        echo "============ display help infomation ============"
        echo "alias cf = create_file_list   : create hdl design file list"
        echo "alias cr = .main clear        : clear the tcl console"
        echo "alias rr = re_run             : compile all files and simulate"
        echo "alias ra = run_all            : compile_changed and simulate"
        echo "alias dh = do_help            : echo help information of this do file"
        echo "alias rl = reload             : reload this tcl file"
        echo "alias qf = quit_f             : force to quit"
        echo "============ end of help infomation ============"
    }
    # ------------- TCL commands alias -------------
    alias cf "create_file_list"
    alias cr ".main clear"
    alias rr "re_run"
    alias ra "run_all"
    alias dh "do_help"
    alias rl "reload"
    alias qf "quit_f"
    # ----------------------------------------------

    # 加载tcl文件先显示帮助
    dh


# REFERENCES
# [0] https://blog.csdn.net/Real003/article/details/88820757
# [1] https://blog.csdn.net/k331922164/article/details/50001035
# [2] https://www.doulos.com/knowhow/tcltk/example-tcl-and-tcltk-scripts-for-eda/modelsim-compile-script/







# 加密源代码
# proc encrypt_src {} {
#     global prj_path
#     set encrypt_path $prj_path/encrypt_src/
#     file mkdir $encrypt_path
#     set paths {}
#     set paths [glob -nocomplain -directory $paths */]
#     lappend paths $prj_path
#     foreach one_path $paths {
#         set vfiles [glob -nocomplain -directory $one_path *.v *.vt]
#         foreach one_file $vfiles {
#             set one_file_path $prj_path
#             vencrypt [append one_file_path $one_file] -d $encrypt_path -e v -quiet
#         }
#     }
#     foreach one_path $paths {
#         set vhdfiles [glob -nocomplain -directory $one_path *.vhd *.vht]
#         foreach one_file $vhdfiles {
#             set one_file_path $prj_path
#             vhencrypt [append one_file_path $one_file] -d $encrypt_path -e vhd -quiet
#         }
#     }
#     puts "encrypt HDL design file(s) successfully!"
# }



# proc display_info {} {
#     global testbench_name sim_time prj_path m_width m_height default_color device
#     puts "========= infomation of current project ========="

#     puts -nonewline "monitor resolution ratio : "
#     puts -nonewline $m_width
#     puts -nonewline "x"
#     puts $m_height

#     puts "\npreset signals color style"
#     puts -nonewline "rst     signals color : "
#     puts [lindex $default_color 0]
#     puts -nonewline "clk     signals color : "
#     puts [lindex $default_color 1]
#     puts -nonewline "en      signals color : "
#     puts [lindex $default_color 2]
#     puts -nonewline "cnt     signals color : "
#     puts [lindex $default_color 3]
#     puts -nonewline "data    signals color : "
#     puts [lindex $default_color 4]
#     puts -nonewline "flag    signals color : "
#     puts [lindex $default_color 5]
#     puts -nonewline "default signals color : "
#     puts [lindex $default_color 6]

#     puts "\nHDL design files of project path : "
#     set paths [glob -nocomplain -directory $prj_path */]
#     lappend paths $prj_path
#     foreach one_path $paths {
#         set vfiles [glob -nocomplain -directory $one_path *.v *.vt *.vhd *.vht]
#         foreach one_file $vfiles {
#             puts $one_file
#         }
#     }

#     puts -nonewline "\nloaded "
#     puts -nonewline $device
#     puts " simulation library list : "
#     if {$device == "altera"} {
#         foreach lib_name [lib_ns::altera_verilog_lib_list] {
#             puts $lib_name.v
#         }
#         foreach lib_name [lib_ns::altera_vhdl_lib_list] {
#             puts $lib_name.v
#         }
#     } else {
#         foreach lib_name [lib_ns::lattice_lib_list] {
#             puts $lib_name
#         }
#     }
    
#     puts -nonewline "\ntestbench name : "
#     puts $testbench_name

#     puts -nonewline "\nsimulation time : "
#     puts $sim_time
#     puts "============= end of infomation ============="
# }


# proc write_report {} {
#     global prj_path
#     set report_path [append prj_path report]
#     if {[file exists $report_path] == 0} {
#         file mkdir $report_path
#     }
#     set txt_file "report.txt"
#     write report -l $report_path/$txt_file

#     set filename "instances"
#     set fd [open $report_path/$filename.txt w+]
#     puts $fd "instances :"
#     puts $fd "\tshow -all"
#     set linstances [find instances -r -nodu /*]
#     foreach instance $linstances {
#         puts -nonewline $fd \t
#         puts -nonewline $fd "show "
#         puts $fd $instance
#     }
#     close $fd
#     puts "write report successfully!"
# }


# # 保留-后边再看
# proc backup_prj {msg} {
#     global testbench_name bkp_path prj_path  
#     set time [clock seconds]
#     set bkp_name $testbench_name
#     append bkp_name [clock format $time -format "_%Y-%m-%d-%H-%M-%S"]
#     if { [file isdirectory $bkp_path] == 0 } {
#         file mkdir $bkp_path
#     }
#     file mkdir $bkp_path/$bkp_name
#     file copy -force $prj_path $bkp_path/$bkp_name
#     append bkp_name "_README.txt"
#     set fd [open $bkp_path/$bkp_name w+]
#     puts $fd $msg
#     close $fd
#     puts "backup current project successfully!"
# }

# # proc save_wave {} {
# #     global sim_time
# #     set time [clock seconds]
# #     set filename "sim_wave_"
# #     append filename [clock format $time -format "%Y-%m-%d-%H-%M-%S"]
# #     vcd add -dumpports -r -optcells -file $filename.vcd -internal -ports *
# #     run $sim_time
# #     vcd flush $filename.vcd
# #     vcd off $filename.vcd
# # }

# # 功能暂时有问题不使用
# # proc load_wave {vcd_file} {
# #     append vcd_file ".vcd"
# #     wave import $vcd_file
# # }


# proc create_file_list {} {
#     global prj_path
#     set prj_files [project filenames]

#     set paths {}
#     set paths [glob -nocomplain -directory $paths */]
#     lappend paths $prj_path

#     set fd [open $prj_path/hdl_design_file_list.tcl w+]
#     foreach one_path $paths {
#         set vfiles [glob -nocomplain -directory $one_path *.v *.vt *.vhd *.vht]
#         foreach one_file $vfiles {
#             set exists_num 0
#             set one_file_path {}
#             append one_file_path $prj_path
#             append one_file_path $one_file
#             foreach one_prj_file $prj_files {
#                 if {$one_file_path == $one_prj_file} {
#                     incr exists_num
#                 }
#             }
#             if {$exists_num == 0} {
#                 puts -nonewline $fd "# "
#             }
#             puts $fd $one_file_path
#         }
#     }
#     close $fd
#     puts "create file list successfully!"
# }


# 需要修改使用--从项目开始到现在多久了
# # How long since project began?
# if {[file isfile start_time.txt] == 0} {
#   set f [open start_time.txt w]
#   puts $f "Start time was [clock seconds]"
#   close $f
# } else {
#   set f [open start_time.txt r]
#   set line [gets $f]
#   close $f
#   regexp {\d+} $line start_time
#   set total_time [expr ([clock seconds]-$start_time)/60]
#   puts "Project time is $total_time minutes"
# }


# # 保留
# proc compile_changed {} {
#     project compileoutofdate
#     puts "compile changed file(s) successfully!"
# }


# # 第一次运行仿真时, 先创建仿真工程
# # creat modelsim or questasim simulation project
# proc new_prj {new_prj_name} {
#     # global prj_path
#     set new_prj_path "./"
#     set new_prj_name ${testbench_name}SimPrj

#     # quit -sim
#     # project close
#     if { [file exists $new_prj_path]==0 } {
#         file mkdir $new_prj_path
#     }
#     project new $new_prj_path $new_prj_name work
#     if { [file exists $new_prj_path/src]==0 } {
#         file mkdir $new_prj_path/src
#     }

#     # file copy -force -- $prj_path/sim.do $new_prj_path
    
#     puts "create new project successfully!"
#     puts "current project path : "
#     pwd
# }

# proc add_file {} {
#     global prj_path auto_add_file
#     set add_count 0
#     set del_count 0
#     set prj_files [project filenames]

#     if {$auto_add_file == 1} {
#         set paths [glob -nocomplain -directory $prj_path */]
#         lappend paths $prj_path
#         foreach one_path $paths {
#             set vfiles [glob -nocomplain -directory $one_path *.v *.vt *.vhd *.vht]
#             foreach one_file $vfiles {
#                 set exists_num 0
#                 foreach one_prj_file $prj_files {
#                     if {$one_file == $one_prj_file} {
#                         incr exists_num
#                     }
#                 }
#                 if {$exists_num == 0} {
#                     project addfile $one_file
#                     incr add_count
#                 }
#             }
#         }
#     } elseif {$auto_add_file == 0} {
#         if {[file exists $prj_path/hdl_design_file_list.tcl] == 0 || \
#             [file size $prj_path/hdl_design_file_list.tcl] <= 1} {
#                 create_file_list
#         }
#         set fd [open $prj_path/hdl_design_file_list.tcl r]
#         set old_content [read -nonewline $fd]
#         close $fd
#         regsub -all " " $old_content {} new_content
#         regsub -all \t+ $new_content {} new_content
#         foreach one_file [split $new_content \n] {
#             if {[regexp ^# $one_file] == 0 && $one_file != "\n"} {
#                 set exists_num 0
#                 foreach one_prj_file $prj_files {
#                     if {$one_file == $one_prj_file} {
#                         incr exists_num
#                     }
#                 }
#                 if {$exists_num == 0} {
#                     project addfile $one_file
#                     incr add_count
#                 }
#             } elseif {[regexp ^# $one_file] == 1 && $one_file != "\n"} {
#                 set one_file [string trim $one_file "#"]
#                 foreach one_prj_file $prj_files {
#                     if { $one_file == $one_prj_file} {
#                         project removefile $one_file
#                         incr del_count
#                     }
#                 }
#             }
#         }
#     }
#     puts -nonewline "add "
#     puts -nonewline $add_count
#     puts " file(s) successfully!"
#     puts -nonewline "remove "
#     puts -nonewline $del_count
#     puts " file(s) successfully!"
# }

# 执行 vsim 命令
# Load the simulation
# eval vsim $top_level

# 添加波形文件
# set wave_patterns {
#                            /*
# }
# set wave_radices {
#                            hexadecimal {data q}
# }

# 添加波形文件
# # If waves are required
# if [llength $wave_patterns] {
#   noview wave
#   foreach pattern $wave_patterns {
#     add wave $pattern
#   }
#   configure wave -signalnamewidth 1
#   foreach {radix signals} $wave_radices {
#     foreach signal $signals {
#       catch {property wave -radix $radix $signal}
#     }
#   }
# }

# 丢弃
# # Run the simulation
# run -all
# 调整波形
# # If waves are required
# if [llength $wave_patterns] {
#   if $tk_ok {wave zoomfull}
# }

# # 显示帮助
# puts {
#   Script commands are:

#   r = Recompile changed and dependent files
#  rr = Recompile everything
#   q = Quit without confirmation
# }


# 暂时无法使用
# Prefer a fixed point font for the transcript
# set PrefMain(font) {Courier 10 roman normal}

# 根据文件列表编译文件
# foreach {library file_list} $library_file_list {
#   vlib $library
#   vmap work $library
#   foreach file $file_list {
#     if { $last_compile_time < [file mtime $file] } {
#     #   if [regexp {.vhdl?$} $file] {
#     #     vcom -93 $file
#     #   } else {
#     #     vlog $file
#     #   }
#       set last_compile_time 0
#     }
#   }
# }
