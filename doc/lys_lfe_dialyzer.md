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
	$ dialyzer --build_plt --apps erts kernel stdlib crypto mnesia
