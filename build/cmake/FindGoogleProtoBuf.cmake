# Try to find protocol buffers (protobuf)
#
# Use as FIND_PACKAGE(ProtocolBuffers)
#
#  PROTOBUF_FOUND - system has the protocol buffers library
#  PROTOBUF_INCLUDE_DIR - the zip include directory
#  PROTOBUF_LIBRARY - Link this to use the zip library
#  PROTOBUF_PROTOC_EXECUTABLE - executable protobuf compiler
#
# And the following command
#
#  WRAP_PROTO(VAR input1 input2 input3..)
#
# Which will run protoc on the input files and set VAR to the names of the created .cc files,
# ready to be added to ADD_EXECUTABLE/ADD_LIBRARY. E.g,
#
#  WRAP_PROTO(PROTO_SRC myproto.proto external.proto)
#  ADD_EXECUTABLE(server ${server_SRC} {PROTO_SRC})
#
# Author: Esben Mose Hansen <[EMAIL PROTECTED]>, (C) Ange Optimization ApS 2008
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

IF (PROTOBUF_LIBRARY AND PROTOBUF_INCLUDE_DIR AND PROTOBUF_PROTOC_EXECUTABLE AND PROTOBUF_PROTOC_VERSION)
	SET(PROTOBUF_FOUND TRUE)
ELSE ()
	IF(CMAKE_TRACE)
		MESSAGE(STATUS " + Looking for protobuf in PROTOBUF_ROOT=${PROTOBUF_ROOT}")
	ENDIF(CMAKE_TRACE)
	FIND_PATH(PROTOBUF_INCLUDE_DIR 
		google/protobuf/stubs/common.h
		PATHS
			/usr/include
			/usr/local/include
			/usr/local/Cellar/protobuf241/2.4.1/include
			${PROTOBUF_ROOT}
			${PROTOBUF_ROOT}/src
	)
	IF(NOT PROTOBUF_INCLUDE_DIR)
		# Attempt to find a source folder if we did not find the include oine
		FIND_PATH(PROTOBUF_INCLUDE_DIR 
			google/protobuf/package_info.h
			PATHS
				${PROTOBUF_ROOT}
				${PROTOBUF_ROOT}/src
		)
	ENDIF(NOT PROTOBUF_INCLUDE_DIR)
	IF(CMAKE_TRACE)
		MESSAGE(STATUS "    PROTOBUF_INCLUDE_DIR=${PROTOBUF_INCLUDE_DIR}")
	ENDIF(CMAKE_TRACE)

	IF(CMAKE_TRACE)
		MESSAGE(STATUS "    Looking for: ${PROTOBUF_LIBRARY_PREFIX}protobuf${PROTOBUF_LIBRARY_SUFFIX}")
	ENDIF(CMAKE_TRACE)
	FIND_LIBRARY(PROTOBUF_LIBRARY_RELEASE 
		NAMES ${PROTOBUF_LIBRARY_PREFIX}protobuf${PROTOBUF_LIBRARY_SUFFIX} ${PROTOBUF_LIBRARY_PREFIX}libprotobuf${PROTOBUF_LIBRARY_SUFFIX}
		PATHS
			/usr/local/Cellar/protobuf241/2.4.1/lib
			${GNUWIN32_DIR}/lib
			${PROTOBUF_LIBRARYDIR_RELEASE}
			${PROTOBUF_LIBRARYDIR}
			${PROTOBUF_ROOT}/build/Release
			${PROTOBUF_ROOT}/cmake/solution/Release
			${PROTOBUF_ROOT}/vsprojects/Release
			${PROTOBUF_ROOT}/vsprojects/x64/Release
			${PROTOBUF_ROOT}/src
	)
	IF(CMAKE_TRACE)
		MESSAGE(STATUS "    PROTOBUF_LIBRARY_RELEASE=${PROTOBUF_LIBRARY_RELEASE}")
	ENDIF(CMAKE_TRACE)
	FIND_LIBRARY(PROTOBUF_LIBRARY_DEBUG 
		NAMES 
			${PROTOBUF_LIBRARY_PREFIX_DEBUG}protobuf${PROTOBUF_LIBRARY_SUFFIX_DEBUG}
			${PROTOBUF_LIBRARY_PREFIX_DEBUG}libprotobuf${PROTOBUF_LIBRARY_SUFFIX_DEBUG}
			${PROTOBUF_LIBRARY_PREFIX_DEBUG}protobufd${PROTOBUF_LIBRARY_SUFFIX_DEBUG}
			${PROTOBUF_LIBRARY_PREFIX_DEBUG}libprotobufd${PROTOBUF_LIBRARY_SUFFIX_DEBUG}
		PATHS
			/usr/local/Cellar/protobuf241/2.4.1/lib
		${GNUWIN32_DIR}/lib
		${PROTOBUF_LIBRARYDIR_DEBUG}
		${PROTOBUF_LIBRARYDIR}
		${PROTOBUF_ROOT}/build/Debug
		${PROTOBUF_ROOT}/cmake/solution/Debug
		${PROTOBUF_ROOT}/vsprojects/Debug
		${PROTOBUF_ROOT}/vsprojects/x64/Debug
	)
	IF(CMAKE_TRACE)
		MESSAGE(STATUS "    PROTOBUF_LIBRARY_DEBUG=${PROTOBUF_LIBRARY_DEBUG}")
	ENDIF(CMAKE_TRACE)
	SET(PROTOBUF_LIBRARY
		debug ${PROTOBUF_LIBRARY_DEBUG}
		optimized ${PROTOBUF_LIBRARY_RELEASE}
	)

	FIND_PROGRAM(PROTOBUF_PROTOC_EXECUTABLE protoc)
	IF(NOT PROTOBUF_PROTOC_EXECUTABLE)
		FIND_PROGRAM(PROTOBUF_PROTOC_EXECUTABLE protoc 
			PATHS
			/usr/local/Cellar/protobuf241/2.4.1/bin
				${PROTOBUF_BINARYDIR}
				${PROTOBUF_ROOT}/cmake/solution/Release
				${PROTOBUF_ROOT}/build/Release
				${PROTOBUF_ROOT}/vsprojects/Release
				${PROTOBUF_ROOT}/vsprojects/x64/Release
				${PROTOBUF_ROOT}/vsprojects/Debug
				${PROTOBUF_ROOT}/vsprojects/x64/Debug
			)
	ENDIF(NOT PROTOBUF_PROTOC_EXECUTABLE)
	IF(CMAKE_TRACE)
		MESSAGE(STATUS "    PROTOBUF_PROTOC_EXECUTABLE=${PROTOBUF_PROTOC_EXECUTABLE}")
	ENDIF(CMAKE_TRACE)

	INCLUDE(FindPackageHandleStandardArgs)
	FIND_PACKAGE_HANDLE_STANDARD_ARGS(protobuf DEFAULT_MSG PROTOBUF_INCLUDE_DIR PROTOBUF_LIBRARY PROTOBUF_PROTOC_EXECUTABLE)

	set(PROTOBUF_PROTOC_VERSION "")
	if (PROTOBUF_PROTOC_EXECUTABLE)
		execute_process(COMMAND ${PROTOBUF_PROTOC_EXECUTABLE} --version OUTPUT_VARIABLE TMP_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
		string(REGEX REPLACE "[a-z]+ ([0-9.]+)$" "\\1" PROTOBUF_PROTOC_VERSION ${TMP_VERSION})
	endif()

	# ensure that they are cached
	SET(PROTOBUF_INCLUDE_DIR ${PROTOBUF_INCLUDE_DIR} CACHE INTERNAL "The protocol buffers include path")
	SET(PROTOBUF_LIBRARY ${PROTOBUF_LIBRARY} CACHE INTERNAL "The libraries needed to use protocol buffers library")
	SET(PROTOBUF_PROTOC_EXECUTABLE ${PROTOBUF_PROTOC_EXECUTABLE} CACHE INTERNAL "The protocol buffers compiler")
	SET(PROTOBUF_PROTOC_VERSION ${PROTOBUF_PROTOC_VERSION} CACHE INTERNAL "The protocol buffers version")
	
	
	
ENDIF ()
