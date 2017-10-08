#include "Helpers.h"

#include <char_buffer.hpp>

#include "ext/mongoose.h"

/**
 * A stream response to a request
 */
namespace Mongoose
{
	std::string Helpers::encode_b64(std::string &str) {
		hlp::char_buffer dst(str.size() * 3);
		hlp::generic_char_buffer<unsigned char> src(str);
		mg_base64_encode(src.get(), src.size(), dst.get());
		return std::string(dst.get());
	}
	std::string Helpers::decode_b64(std::string &str) {
		hlp::char_buffer dst(str.size() * 3);
		hlp::generic_char_buffer<unsigned char> src(str);
		mg_base64_decode(src.get(), src.size(), dst.get());
		return std::string(dst.get());
	}
}