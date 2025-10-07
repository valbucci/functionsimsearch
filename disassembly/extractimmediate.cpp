#include <algorithm>
#include <regex>
#include <string>
#include <iostream>
#include <cstdint>
#include <vector>
#include <cstdlib>

// this regex was provided courtesy of mark brand.
// constexpr char extraction_regex[] =
//   "(?:\\W|0x|^)([[:xdigit:]]+)(?:h|\\W|$)";

// Our immediates come from capstone, and they are already normalized: #0xabcd or #-0xabcd
constexpr char extraction_regex[] =
  "#(-?0x[[:xdigit:]]+)";

// cleaned up the original code
size_t ExtractImmediateFromString(const std::string& operand,
  std::vector<uint64_t>* results) {
  static std::regex re(extraction_regex, std::regex_constants::ECMAScript);
  size_t count = 0;
  std::smatch match;
  if (std::regex_match(operand, match, re)) {
      if (match.ready()) {
        std::string immediate = match[1];
        uint64_t val = strtoull(immediate.c_str(), nullptr, 16);
        results->push_back(val);
        count++;
      }
  }
  return count;
}
