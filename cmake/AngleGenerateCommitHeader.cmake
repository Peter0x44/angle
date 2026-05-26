if(NOT DEFINED OUTPUT_FILE OR OUTPUT_FILE STREQUAL "")
    message(FATAL_ERROR "OUTPUT_FILE is required.")
endif()

if(NOT DEFINED SOURCE_DIR OR SOURCE_DIR STREQUAL "")
    message(FATAL_ERROR "SOURCE_DIR is required.")
endif()

set(angle_commit_hash "unknown hash")
set(angle_commit_date "unknown date")
set(angle_commit_position "0")
set(angle_commit_hash_size 12)

if(DEFINED ENV{ANGLE_UPSTREAM_HASH} AND NOT "$ENV{ANGLE_UPSTREAM_HASH}" STREQUAL "")
    set(angle_commit_hash "$ENV{ANGLE_UPSTREAM_HASH}")
else()
    execute_process(
        COMMAND git rev-parse --is-inside-work-tree
        WORKING_DIRECTORY "${SOURCE_DIR}"
        RESULT_VARIABLE angle_git_result
        OUTPUT_VARIABLE angle_git_inside_work_tree
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)

    if(angle_git_result EQUAL 0 AND angle_git_inside_work_tree STREQUAL "true")
        execute_process(
            COMMAND git rev-parse --short=${angle_commit_hash_size} HEAD
            WORKING_DIRECTORY "${SOURCE_DIR}"
            RESULT_VARIABLE angle_hash_result
            OUTPUT_VARIABLE angle_hash_output
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET)
        if(angle_hash_result EQUAL 0 AND NOT angle_hash_output STREQUAL "")
            set(angle_commit_hash "${angle_hash_output}")
        endif()

        execute_process(
            COMMAND git show -s --format=%ci HEAD
            WORKING_DIRECTORY "${SOURCE_DIR}"
            RESULT_VARIABLE angle_date_result
            OUTPUT_VARIABLE angle_date_output
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET)
        if(angle_date_result EQUAL 0 AND NOT angle_date_output STREQUAL "")
            set(angle_commit_date "${angle_date_output}")
        endif()

        execute_process(
            COMMAND git rev-list HEAD --count
            WORKING_DIRECTORY "${SOURCE_DIR}"
            RESULT_VARIABLE angle_position_result
            OUTPUT_VARIABLE angle_position_output
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET)
        if(angle_position_result EQUAL 0 AND NOT angle_position_output STREQUAL "")
            set(angle_commit_position "${angle_position_output}")
        endif()
    endif()
endif()

get_filename_component(angle_output_dir "${OUTPUT_FILE}" DIRECTORY)
file(MAKE_DIRECTORY "${angle_output_dir}")

set(angle_temp_file "${OUTPUT_FILE}.tmp")
file(WRITE "${angle_temp_file}"
    "#define ANGLE_COMMIT_HASH \"${angle_commit_hash}\"\n"
    "#define ANGLE_COMMIT_HASH_SIZE ${angle_commit_hash_size}\n"
    "#define ANGLE_COMMIT_DATE \"${angle_commit_date}\"\n"
    "#define ANGLE_COMMIT_POSITION ${angle_commit_position}\n")
execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${angle_temp_file}" "${OUTPUT_FILE}")
file(REMOVE "${angle_temp_file}")