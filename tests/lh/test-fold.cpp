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

    for (std::size_t i=0, N=42 ;
            i!=N ;
            ++i)
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

void embedded_ctrl_stments()
{
    if (t1) {
        if (t11) {
            a11();
        } else if (t12) {
            a12();
        } else {
            a1x();
        }
    } else {
        a2();
    }
}

int typical_main (int argc, char **argv)
{
    try {
        bool verbose = false;
        bool noexec  = false;
        std::string output_dir;
        std::vector<std::string> files;

        for (int i=1; i!=argc ; ++i) {
            const std::string s = argv[i];
            if (argv[i][0] == '-') {
                if (s == "-h" || s=="--help" ) {
                    std::cout << usage(argv[0]) << "\n";
                    return EXIT_SUCCESS;
                } else if (s == "-n" || s == "--noexec") {
                    noexec = true;
                } else if (s == "-v" || s == "--verbose") {
                    verbose = true;
                } else if (s == "-o" || s == "--output") {
                    if (i+1 == argc)
                        throw std::runtime_error(usage(argv[0], "Not enough arguments to specify output directory"));
                    output_dir = argv[++i]; // yes i is increment. But the bound is made the line before.
                } else {
                    throw std::runtime_error(std::string(argv[0])+": Unexpected option: '"+s+"'");
                }
            } else {
                files.push_back(s);
            }
        }
        if (files.empty())
            throw std::runtime_error(usage(argv[0], "No file specified"));
        if (output_dir.empty() && !noexec)
            throw std::runtime_error(usage(argv[0], "Output directory not specified"));

        for (std::vector<std::string>::const_iterator b = files.begin(), e = files.end()
                ; b != e
                ; ++b
            )
        {
            std::cout << b << "\n";
        }

        return EXIT_SUCCESS;
    } catch (std::exception const& e) {
        std::cerr << e.what() << "\n";
    }
    return EXIT_FAILURE;
}


// From http://stackoverflow.com/questions/8316765/vim-foldexpr-for-including-multiline-function-signatures/
void ClassName::FunctionName(LongType1 LongArgument1,
                             LongType2 LongArgument2,
                             LongType3 LongArgument3) {
  ...
}

void if_def() {
#if defined(foo) \
    && define(fii)
    bla;
#  ifdef zzz
    zzz;
#  endif
    bli;
#elif defined(bar)
    blie;
#  ifndef eee
    eee;
#  endif
    bla;
#endif
}
