%skeleton "lalr1.cc"
%require "3.5"

%defines
%define api.token.constructor
%define api.value.type variant
%define parse.assert

%code requires {
    #include <string>
    /* Forward declaration of classes in order to disable cyclic dependencies */
    class Scanner;
    class Driver;
}


%define parse.trace
%define parse.error verbose

%code {
    #include "driver.hh"
    #include "location.hh"

    /* Redefine parser to use our function from scanner */
    static yy::parser::symbol_type yylex(Scanner &scanner, Driver& driver) {
        return scanner.ScanToken();
    }
}

%lex-param { Scanner &scanner }
%lex-param { Driver &driver }
%parse-param { Scanner &scanner }
%parse-param { Driver &driver }

%locations

%define api.token.prefix {TOK_}
// token name in variable
%token
    END 0 "end of file"
    ASSIGN ":="
    MINUS "-"
    PLUS "+"
    STAR "*"
    SLASH "/"
    LPAREN "("
    RPAREN ")"
    SEMICOLON ";"
    COLON ":"
    VAR "var"
    TYPE "type"
    PRINT "writeln"
    BEGIN "begin"
    PREND "end"
    PROGRAM "program"
;

%token <std::string> IDENTIFIER "identifier"
%token <int> NUMBER "number"
%nterm <int> exp

// Prints output in parsing option for debugging location terminal
%printer { yyo << $$; } <*>;

%%
%left "+" "-";
%left "*" "/";

%start program;

program: PROGRAM IDENTIFIER ";" code
			{
			driver.name = $2;
			std::cout << "Running program " << driver.name << " ..." << std::endl;
			};

code: BEGIN unit PREND {};

unit:     %empty {}
	| unit assignment;
	| unit declaration;
	| unit print;

print: PRINT "(" exp ")" ";" { std::cout << $3 << std::endl;};

declaration: decl ":" TYPE ";" {};

decl: VAR IDENTIFIER {driver.variables[$2];};

assignment:
    IDENTIFIER ":=" exp ";" {
        driver.variables[$1] = $3;
        if (driver.location_debug) {
            std::cerr << driver.location << std::endl;
            driver.result = -1;
        }

        driver.result = 0;
    }
    | error ";" {
    	// Hint for compilation error, resuming producing messages
    	std::cerr << "You should provide assignment in the form: variable := expression ; " << std::endl;
    	yyerrok;
    };

exp:
    NUMBER
    | IDENTIFIER {$$ = driver.variables[$1];}
    | exp "+" exp {$$ = $1 + $3; }
    | exp "-" exp {$$ = $1 - $3; }
    | exp "*" exp {$$ = $1 * $3; }
    | exp "/" exp {$$ = $1 / $3; }
    | "(" exp ")" {$$ = $2; };

%%

void
yy::parser::error(const location_type& l, const std::string& m)
{
  std::cerr << l << ": " << m << '\n';
}
