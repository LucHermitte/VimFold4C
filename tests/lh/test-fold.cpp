// The includes...
#include <string>
#include <cassert>
#include <iostream>


// One line class
struct Foo {};

// a class
struct Bar {
    // Multi-lines fn definition, with no body
    Bar()
        : m_foo(42)
        , m_bar("bar")
        {}
    // one-liner fn definition with no body
    ~Bar() {}

    // one-liner fn definition with a body
    int getFoo() const { return m_foo;}
    // multi-lines fn definition with a body
    void setFoo(int foo) {
        assert(foo);
        m_foo = foo;
    } 

private:
    int         m_foo;
    std::string m_bar;
};

void control_statements() {
    // ifs ...
    if (42 == 41) {
        std::cout << "WTF?\n";
    }

    if (42 == 41)
        std::cout << "WTF?\n";

    if (42 == 41)
    {
        std::cout << "WTF?\n";
    }

    if (42 == 41) {
        std::cout << "WTF?\n";
    } else {
        std::cout << "OK\n";
    }

    if (42 == 41)
        std::cout << "WTF?\n";
    else
        std::cout << "OK\n";

    if (42 == 41)
    {
        std::cout << "WTF?\n";
    }
    else
    {
        std::cout << "OK\n";
    }

    // Whiles
    //
    // fors ...
    //
    // switch
    //
    // try catch

}
