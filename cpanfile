requires 'perl', '5.008005';

requires 'Package::Stash', '0.36';
requires 'Sub::Name',      '0.09';

on test => sub {
    requires 'Test::Lib',  '0.002';
    requires 'Test::Most', '0.34';
};
