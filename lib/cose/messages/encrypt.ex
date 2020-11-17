defmodule COSE.Messages.Encrypt do
  defstruct [:phdr, :uhdr, :ciphertext, :recipients, :payload, :aad]

  @spec build(binary, map, map) :: map
  def build(payload, recipient \\ %{}, phdr \\ %{}, uhdr \\ %{}) do
    %__MODULE__{
      phdr: phdr,
      uhdr: uhdr,
      payload: COSE.tag_as_byte(payload),
      aad: COSE.tag_as_byte(<<>>),
      recipients: [recipient]
    }
  end

  def to_array(msg) do
    [
      COSE.Headers.tag_phdr(msg.phdr),
      msg.uhdr,
      msg.ciphertext,
      COSE.Messages.Recipient.encode_many(msg.recipients)
    ]
  end

  def encode_cbor(msg, key, iv) do
    array_msg = encrypt(msg, key, iv) |> to_array()

    CBOR.encode(%CBOR.Tag{tag: 96, value: array_msg})
  end

  def decode_cbor(cbor_msg) do
    {:ok, %CBOR.Tag{tag: 96, value: [phdr, uhdr, ciphertext, recipients]}, _} =
      CBOR.decode(cbor_msg)

    %__MODULE__{
      phdr: COSE.Headers.decode_phdr(phdr),
      uhdr: uhdr,
      ciphertext: ciphertext,
      recipients: COSE.Messages.Recipient.decode_many(recipients)
    }
  end

  def enc_structure(msg, external_aad \\ <<>>) do
    [
      "Encrypt",
      (msg.phdr == %{} && COSE.tag_as_byte(<<>>)) || COSE.Headers.tag_phdr(msg.phdr),
      COSE.tag_as_byte(external_aad)
    ]
  end

  def encrypt(msg, key, iv, external_aad \\ <<>>) do
    aad = msg |> enc_structure(external_aad) |> CBOR.encode()
    payload = CBOR.encode(msg.payload)

    {encrypted, tag} =
      :crypto.crypto_one_time_aead(:aes_128_ccm, key.k, iv, payload, aad, 8, true)

    Map.put(msg, :ciphertext, COSE.tag_as_byte(encrypted <> tag))
  end

  def decrypt(msg, key, iv, external_aad \\ <<>>) do
    aad = msg |> enc_structure(external_aad) |> CBOR.encode()
    {encrypted, tag} = split_encrypted_tag(msg.ciphertext.value)

    :crypto.crypto_one_time_aead(:aes_128_ccm, key.k, iv, encrypted, aad, tag, false)
    |> case do
      dec_payload when is_binary(dec_payload) ->
        {:ok, payload, _} = CBOR.decode(dec_payload)
        {:ok, Map.put(msg, :payload, payload)}

      error ->
        error
    end
  end

  def split_encrypted_tag(ciphertext, tag_len \\ 8) do
    encrypted_len = byte_size(ciphertext) - tag_len
    <<encrypted::binary-size(encrypted_len), tag::binary-size(tag_len)>> = ciphertext
    {encrypted, tag}
  end
end
