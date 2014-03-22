# Dialyzer & Type Specifications

> Lisp Flavoured Erlang function and data type specifications and
> definitions for Dialyzer.

Within this document we will provide the necessary tools to start
reinforcing your LFE code with type specifications and
definitions. These will (soon!) be readable by the Dialyzer tool for
even more amazing distributed Lisp code!

This document borrows heavily from the
[Learn You Some Erlang](https://learnyousomeerlang.com) chapter on
[Type Specifications and Erlang](https://learnyousomeerlang.com/dialyzer). It
is of course focused on how to utilise the type system in LFE. This
system is built on top of the functionality that Dialyzer provides,
any information that may be lacking here will more than likely appear
on the Learn You Some Erlang site. If you think it should be included
here, lodge an issue!

If you're running a sufficiently recent version of Erlang, then the
`dialyzer` module should already be available to you. However in order
for it to be of any use, you must prepare the PLT (Persistent Lookup
Table). This table stores information about modules and
applications. We won't spend too long on setting up Dialyzer as there
are already some great guides
[here](http://learnyousomeerlang.com/dialyzer) and
[here](http://gertm.blogspot.com.au/2012/06/getting-started-with-dialyzer-for.html)
and of course the
[`man` page](http://www.erlang.org/doc/man/dialyzer.html).

Building the PLT the first time:
```
$ dialyzer --build_plt --apps erts kernel stdlib crypto mnesia sasl
```

Throughout this guide we will begin with demonstrating what the
'un-typed' version of the code will look like. Then we enhance with
types to demonstrate their use in various situations.

> Should I briefly cover some Dialyzer details like type inference and
> discrepencies and how the sucess typing system works here? Or just
> completely defer to the LYSE/dialyzer page? I feel like I should
> cover it at least briefly so we know what to avoid in our LFE types
> as well. Because they'll look different... 

### Types of Types

The type system for LFE supports the Erlang _union_ and _built-in_
types. With _singleton_ types as well that simply refer to the value
itself. For example:
```
'|some atom|	| Any atom can be its own singleton type
42				| A given integer
#() or (list)	| An empty list
#{} or (tuple)	| An empty tuple
#B or (binary)	| An empty binary
```

Below is a table of some Erlang types, and their LFE
counterparts. Note that somethings become reserved words inside of a
type definition because of the availability of specific types, such as
process ids, ports, or references.

| Erlang Term | LFE Term | Description |
|-------------|----------|-------------|
| `any()` | `'any` | Any Erlang term |
| `none()` | `'none` | Special Dialyzer term for deliberately breaking things.| 
| `pid()` | `'pid` | A process identifier |
| `port()` | `'port` | A port is the representation of a file description, socket, et al. In the shell they appear as #Port<0.638> |
| `reference()` | `'ref` | Unique values returned by (make_ref) or erlang:monitor/2 |
| `atom()` | `'atom` | General atom type |
| `'specific atom'` | `'|specific atom |'` | A specific atom singleton.|
| `binary()` | `#B` | General binary type |
| `<<_:N>>` | `#B(size N)` | Binary of known size where `N` is the size |
| `<<_:_*N>>` | `#B(_ (size N) *)` | Binary of `N` size but unspecified length |
| `<<_:N,_:_*K>>` | `#B(_ (size N) _ (size K) *)` | Combination of the above specifiers |
| `integer()` | `'int` or `'integer` | Any integer |
| `N..M` | `(.. N M)` | A range of integers. From `N` to `M`, Dialyzer reserves the right to expand this range into a larger when. |
| `non_neg_integer()` | `'non_neg_int` or `'non_neg_integer` | Integer that is greater or equal to 0 |
| `pos_integer()` | `'pos_int` or `'pos_integer` | Integer greater than 0 |
| `neg_integer()` | ``neg_int` or `'neg_integer` | Integers up to and including `-1` |
| `float()` | `'float` | Any floating point number. |
| `fun()` | `(fun)` | Any kind of function. |
| `fun((...) -> Type)` | `(fun (..) Type)` | An anonymous function of any arity that returns `Type`. `(fun (..) 'int)`, for example. |
| `fun(() -> Type)` | `(fun () Type)` | An anonymous function of 0 arity that returns `Type`. |
| `fun((Type1,Type2) -> Type)` | `(fun (Type1 Type2) Type)` | An anonymous function of a specific arity that only accepts the types specified in the given order, and returns `Type`. `(fun ('int 'float) #('int))`, for example. |



#### Examples
### Function Types
#### Examples
### Exporting Types
#### Examples
