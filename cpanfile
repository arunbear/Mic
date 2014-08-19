requires 'perl', '5.008005';

requires 'Package::Stash', '0.36';

on test => sub {
    requires 'Test::Lib', '0.002';
};
