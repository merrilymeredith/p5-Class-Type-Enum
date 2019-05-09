# vim: ft=perl

requires 'perl', '5.8.6';

requires 'Class::Method::Modifiers';
requires 'List::Util', '1.33';
requires 'namespace::clean';

on test => sub {
  requires 'Moo', '1.00600';
  requires 'Type::Tiny';
};

feature 'type_constraint', 'Create a Type::Tiny constraint for your enum classes' => sub {
  suggests 'Type::Tiny';
};

