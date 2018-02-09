#include <iostream>
#include <cmath>


/** @brief test...
 * bla...
 */
int main (int argc, char* argv[])
{

#ifndef NDEBUG
  std::clog << "NOTE: '" << argv[0] << "' COMPILED ON " << __TIME__ << " " <<
  __DATE__ << " AS DEBUG VERSION." << std::endl;
#endif

  std::cout << "Hello World" << std::endl;
}
