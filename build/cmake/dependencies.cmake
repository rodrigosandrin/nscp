cmake_minimum_required(VERSION 2.8.12)


#############################################################################
#
# Find all dependencies and report anything missing.
#
#############################################################################
MESSAGE(STATUS "Looking for dependencies:")
find_package (Python3 COMPONENTS Interpreter Development)
FIND_PACKAGE(TinyXML2)
FIND_PACKAGE(CryptoPP)
FIND_PACKAGE(LUA)
if(NOT LUA_FOUND)
	FIND_PACKAGE(LUASource)
endif()

FIND_PACKAGE(PROTOC_GEN_LUA)
FIND_PACKAGE(PROTOC_GEN_JSON)
FIND_PACKAGE(ProtocGenMd)
FIND_PACKAGE(GoogleProtoBuf)
FIND_PACKAGE(GoogleTest)
FIND_PACKAGE(GoogleBreakpad)
FIND_PACKAGE(OpenSSL)
FIND_PACKAGE(Miniz)
IF(WIN32)
#	SET(Boost_USE_STATIC_LIBS_OLD ${Boost_USE_STATIC_LIBS})
#	SET(Boost_USE_STATIC_RUNTIME_OLD ${Boost_USE_STATIC_RUNTIME})
#	SET(Boost_USE_STATIC_LIBS		ON)
#	SET(Boost_USE_STATIC_RUNTIME	ON)
#	FIND_PACKAGE(Boost COMPONENTS system filesystem)
#	SET(Boost_SYSTEM_LIBRARY_STATIC ${Boost_SYSTEM_LIBRARY})
#	SET(Boost_FILESYSTEM_LIBRARY_STATIC ${Boost_FILESYSTEM_LIBRARY})
#	SET(Boost_USE_STATIC_LIBS ${Boost_USE_STATIC_LIBS_OLD})
#	SET(Boost_USE_STATIC_RUNTIME ${Boost_USE_STATIC_RUNTIME_OLD})
#	UNSET(Boost_LIBRARIES)
ELSE()
#	FIND_PACKAGE(Boost COMPONENTS system filesystem)
ENDIF()
FIND_PACKAGE(Boost COMPONENTS system filesystem thread regex date_time program_options python311 chrono)
FIND_PACKAGE(Json_Spirit)
FIND_PACKAGE(Mkdocs)
FIND_PACKAGE(CSharp)

IF(WIN32)
	INCLUDE(${BUILD_CMAKE_FOLDER}/wix.cmake)
ELSE(WIN32)
#s	FIND_PACKAGE(Threads REQUIRED)
#	FIND_PACKAGE(ICU REQUIRED)
	FIND_PACKAGE(IConv)
ENDIF(WIN32)
MESSAGE(STATUS "Found dependencies:")
IF(Python3_Interpreter_FOUND)
	MESSAGE(STATUS " - python(exe) found: ${Python3_EXECUTABLE}")
ELSE()
	MESSAGE(STATUS " ! python(exe) not found: TODO")
ENDIF()
IF(Python3_Development_FOUND)
	MESSAGE(STATUS " - python(lib) found: ${Python3_LIBRARIES}")
ELSE()
	MESSAGE(STATUS " ! python(lib) not found: TODO")
ENDIF()
IF (TINYXML2_FOUND)
	MESSAGE(STATUS " - tinyXML found: ${TINYXML2_INCLUDE_DIR}")
ELSE(TINYXML2_FOUND)
	MESSAGE(STATUS " ! tinyXML not found: TODO")
ENDIF(TINYXML2_FOUND)
IF(CRYPTOPP_FOUND)
	MESSAGE(STATUS " - crypto++(lib) found in: ${CRYPTOPP_INCLUDE_DIR} (${CRYPTOPP_LIBRARIES})")
ELSE(CRYPTOPP_FOUND)
	MESSAGE(STATUS " ! crypto++ not found: ${CRYPTOPP_ROOT}")
ENDIF(CRYPTOPP_FOUND)
IF (LUA_FOUND)
	MESSAGE(STATUS " - lua found in ${LUA_INCLUDE_DIR}")
ELSE(LUA_FOUND)
	if(LUA_SOURCE_FOUND)
		MESSAGE(STATUS " - lua source found in ${LUA_SOURCE_DIR}")
	else()
		MESSAGE(STATUS " ! lua not found: LUA_INCLUDE_DIR=${LUA_INCLUDE_DIR} or LUA_SOURCE_DIR=${LUA_SOURCE_DIR}")
	endif()
ENDIF(LUA_FOUND)
IF(PROTOC_GEN_LUA_FOUND)
	MESSAGE(STATUS " - lua.protocol_buffers found in: ${PROTOC_GEN_LUA_BIN}")
ELSE(PROTOC_GEN_LUA_FOUND)
	MESSAGE(STATUS " ! lua.protocol_buffers not found: PROTOC_GEN_LUA=${PROTOC_GEN_LUA_BIN}")
ENDIF(PROTOC_GEN_LUA_FOUND)
IF(PROTOC_GEN_JSON_FOUND)
	MESSAGE(STATUS " - json.protocol_buffers found in: ${PROTOC_GEN_JSON_BIN}")
ELSE(PROTOC_GEN_JSON_FOUND)
	MESSAGE(STATUS " ! json.protocol_buffers not found: PROTOC_GEN_JSON_BIN=${PROTOC_GEN_JSON_BIN}")
ENDIF(PROTOC_GEN_JSON_FOUND)
IF(PROTOC_GEN_MD_FOUND)
	MESSAGE(STATUS " - md.protocol_buffers found in: ${PROTOC_GEN_MD_BIN}")
ELSE(PROTOC_GEN_MD_FOUND)
	MESSAGE(STATUS " ! md.protocol_buffers not found: PROTOC_GEN_MD_BIN=${PROTOC_GEN_MD_BIN}")
ENDIF(PROTOC_GEN_MD_FOUND)
IF(PROTOBUF_FOUND)
    MESSAGE(STATUS " - protocol buffers found in: ${PROTOBUF_INCLUDE_DIR} / ${PROTOBUF_LIBRARY}")
    MESSAGE(STATUS " - protocol buffers compiler: ${PROTOBUF_PROTOC_EXECUTABLE}")
ELSE(PROTOBUF_FOUND)
	MESSAGE(STATUS " ! protocol buffers not found: PROTOBUF_ROOT=${PROTOBUF_ROOT}")
ENDIF(PROTOBUF_FOUND)
IF(BREAKPAD_FOUND)
	MESSAGE(STATUS " - google breakpad found in: ${BREAKPAD_INCLUDE_DIR}")
ELSE(BREAKPAD_FOUND)
	MESSAGE(STATUS " ! google breakpad not found: TODO=${BREAKPAD_EXCEPTION_HANDLER_INCLUDE_DIR}")
ENDIF(BREAKPAD_FOUND)
IF(GTEST_FOUND)
	MESSAGE(STATUS " - google test found in: ${GTEST_INCLUDE_DIR}")
ELSE(GTEST_FOUND)
	MESSAGE(STATUS " ! google test not found: GTEST_ROOT=${GTEST_ROOT}")
ENDIF(GTEST_FOUND)
IF(OPENSSL_FOUND)
	MESSAGE(STATUS " - OpenSSL found in: ${OPENSSL_INCLUDE_DIR} / ${OPENSSL_LIBRARIES}")
ELSE(OPENSSL_FOUND)
	MESSAGE(STATUS " ! OpenSSL not found TODO=${OPENSSL_INCLUDE_DIR}")
ENDIF(OPENSSL_FOUND)
IF(Boost_FOUND)
	MESSAGE(STATUS " - boost found in: ${Boost_INCLUDE_DIRS} / ${Boost_LIBRARY_DIRS}")
ELSE(Boost_FOUND)
	MESSAGE(STATUS " ! boost not found: BOOST_ROOT=${BOOST_ROOT}")
ENDIF(Boost_FOUND)
IF(JSON_SPIRIT_FOUND)
	MESSAGE(STATUS " - Json Spirit found in: ${JSON_SPIRIT_INCLUDE_DIR}")
ELSE(JSON_SPIRIT_FOUND)
	MESSAGE(STATUS " ! Json Spirit not found: JSON_SPRIT_DIR=${JSON_SPRIT_DIR}")
ENDIF(JSON_SPIRIT_FOUND)
IF(CSHARP_FOUND)
  IF(WIN32)
	MESSAGE(STATUS " - CSharp found: ${CSHARP_TYPE} ${CSHARP_VERSION}")
  ELSE()
	MESSAGE(STATUS " - CSharp found: ${CSHARP_TYPE} ${CSHARP_VERSION} (but disabled sine it is not currently supported on non windows")
  ENDIF()
ELSE()
	MESSAGE(STATUS " ! CSharp not found")
ENDIF()
IF(MINIZ_FOUND)
	MESSAGE(STATUS " - Miniz found in: ${MINIZ_INCLUDE_DIR}")
ELSE(MINIZ_FOUND)
	MESSAGE(STATUS " ! Miniz not found: MINIZ_INCLUDE_DIR=${MINIZ_INCLUDE_DIR}")
ENDIF(MINIZ_FOUND)
IF(MKDOCS_FOUND)
	MESSAGE(STATUS " - MKDocs found in: ${MKDOCS_EXECUTABLE}")
ELSE(MKDOCS_FOUND)
	MESSAGE(STATUS " ! MKDocs not found: MKDOCS_DIR=${MKDOCS_DIR}")
ENDIF(MKDOCS_FOUND)

IF(WIN32)
	IF(WIX_FOUND)
		MESSAGE(STATUS " - wix found in: ${WIX_ROOT_DIR}")
	ELSE(WIX_FOUND)
		MESSAGE(STATUS " ! wix not found: WIX_ROOT_DIR=${WIX_ROOT_DIR}")
	ENDIF(WIX_FOUND)
ENDIF(WIN32)
IF(NOT WIN32)
#	IF(CMAKE_USE_PTHREADS_INIT)
#		MESSAGE(STATUS " - POSIX threads found: TODO")
#	 ELSE(CMAKE_USE_PTHREADS_INIT)
#		MESSAGE(STATUS " ! POSIX threads not found: TODO")
#	ENDIF(CMAKE_USE_PTHREADS_INIT)
#	IF(NOT ICU_FOUND)
#		MESSAGE(STATUS "ICU package not found.")
#	ELSE(NOT ICU_FOUND)
#		ADD_DEFINITIONS( -DSI_CONVERT_ICU )
#	ENDIF(NOT ICU_FOUND)
	IF(ICONV_FOUND)
		MESSAGE(STATUS " - IConv found in: ${ICONV_INCLUDE_DIR}")
	ELSE(ICONV_FOUND)
		MESSAGE(STATUS " ! IConv package not found.")
	ENDIF(ICONV_FOUND)
#  ICONV_INCLUDE_DIR
ENDIF(NOT WIN32)


