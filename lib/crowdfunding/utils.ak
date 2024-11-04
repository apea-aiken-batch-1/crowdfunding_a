use aiken/primitive/bytearray
use cardano/address.{Credential, Script, VerificationKey}
use crowdfunding/types.{Address}

pub fn credential_to_hash(credential: Credential) {
  when credential is {
    VerificationKey(verification_key_hash) -> verification_key_hash
    Script(script_hash) -> script_hash
  }
}

pub fn compare_address(l: Address, r: Address) {
  bytearray.compare(l.pkh, r.pkh)
}
