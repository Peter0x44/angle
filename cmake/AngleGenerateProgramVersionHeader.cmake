if(NOT DEFINED OUTPUT_FILE OR OUTPUT_FILE STREQUAL "")
    message(FATAL_ERROR "OUTPUT_FILE is required.")
endif()

if(NOT DEFINED RESPONSE_FILE OR RESPONSE_FILE STREQUAL "")
    message(FATAL_ERROR "RESPONSE_FILE is required.")
endif()

if(NOT EXISTS "${RESPONSE_FILE}")
    message(FATAL_ERROR "Response file does not exist: ${RESPONSE_FILE}")
endif()

file(STRINGS "${RESPONSE_FILE}" angle_program_version_inputs)

set(angle_program_version_seed "")
foreach(input_file IN LISTS angle_program_version_inputs)
    if(input_file STREQUAL "")
        continue()
    endif()

    if(EXISTS "${input_file}")
        file(MD5 "${input_file}" angle_input_digest)
        string(MD5 angle_program_version_seed
            "${angle_program_version_seed}${input_file}${angle_input_digest}")
    endif()
endforeach()

if(angle_program_version_seed STREQUAL "")
    string(MD5 angle_program_version_seed "")
endif()

get_filename_component(angle_output_dir "${OUTPUT_FILE}" DIRECTORY)
file(MAKE_DIRECTORY "${angle_output_dir}")

set(angle_temp_file "${OUTPUT_FILE}.tmp")
file(WRITE "${angle_temp_file}"
    "#define ANGLE_PROGRAM_VERSION \"${angle_program_version_seed}\"\n"
    "#define ANGLE_PROGRAM_VERSION_HASH_SIZE 16\n")
execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${angle_temp_file}" "${OUTPUT_FILE}")
file(REMOVE "${angle_temp_file}")