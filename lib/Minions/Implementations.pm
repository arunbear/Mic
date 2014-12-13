=head2 Configuring an implementation package

An implementation package can also be configured with a package variable C<%__Meta> with the following keys:

=head3 has => HASHREF

This declares attributes of the implementation, mapping the name of an attribute to a hash with keys described in
the following sub sections.

An attribute called "foo" can be accessed via it's object like this:

    $self->{$$}{foo}

Objects created by Minions are hashes,
and are locked down to allow only keys declared in the "has" (implementation or role level)
declarations. This is done to prevent accidents like mis-spelling an attribute name.

=head4 default => SCALAR | CODEREF

The default value assigned to the attribute when the object is created. This can be an anonymous sub,
which will be excecuted to build the the default value (this would be needed if the default value is a reference,
to prevent all objects from sharing the same reference).

=head4 assert => HASHREF

This is like the C<assert> declared in a class package, except that these assertions are not run at
construction time. Rather they are invoked by calling the semiprivate ASSERT routine.

=head4 handles => ARRAYREF | HASHREF | SCALAR

This declares that methods can be forwarded from the object to this attribute in one of three ways
described below. These forwarding methods are generated as public methods if they are declared in
the interface, and as semiprivate routines otherwise.

=head4 handles => ARRAYREF

All methods in the given array will be forwarded.

=head4 handles => HASHREF

Method forwarding will be set up such that a method whose name is a key in the given hash will be
forwarded to a method whose name is the corresponding value in the hash.

=head4 handles => SCALAR

The scalar is assumed to be a role, and methods provided directly (i.e. not including methods in sub-roles) by the role will be forwarded.

=head4 reader => SCALAR

This can be a string which if present will be the name of a generated reader method.

This can also be the numerical value 1 in which case the generated reader method will have the same name as the key.

Readers should only be created if they are logically part of the class API.

=head3 semiprivate => ARRAYREF

Any subroutines in this list will be semiprivate, i.e. they will not be callable as regular object methods but
can be called using the syntax:

    $obj->{'!'}->do_something(...)

=head3 roles => ARRAYREF

A reference to an array containing the names of one or more Role packages that define the subroutines declared in the interface.

The packages may also contain other subroutines not declared in the interface that are for internal use in the package.
These won't be callable using the C<$minion-E<gt>command(...)> syntax.

