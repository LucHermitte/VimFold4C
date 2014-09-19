// The includes...
#include <string>
#include <cassert>
#include <iostream>


// One line class
struct Foo { };

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
    while (foo) {
        act;
    }

    while (foo)
    {
        act;
    }

    while
        (foo) {
        act;
    }

    while
        (foo)
        {
            act;
        }

    // do Whiles
    do {
        act;
    } while (foo) ;

    do
    {
        act;
    } while (foo) ;

    do 
    {
        act;
    }
    while (foo) ;

    do {
        act;
    } while 
    (foo) ;


    // fors ...
    for (std::size_t i=0, N=42; i!=N ; ++i) {
        act;
    }

    for (std::size_t i=0, N=42; i!=N ; ++i)
    {
        act;
    }

    for (std::size_t i=0, N=42
            ; i!=N
            ; ++i)
    {
        act;
    }

    // switch
    switch(expr){
        case c1:
            {
                code;
                break;
            }
        case c2:
                code;
                break;
        case c3:
        case c4:
                code;
                break;
        default:
            {
                default_code;
                break;
            }
    }
    //
    // try catch

}
