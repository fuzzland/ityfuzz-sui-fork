script {
#[allow(unused_type_parameter)]
/// This script does really nothing but just aborts.
fun some_script<Token>(_account: signer, code: u64) {
    abort code
}
}
