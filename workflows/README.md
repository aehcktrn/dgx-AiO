# Workflows

`z-image-turbo.api.json` is the API-format ComfyUI workflow used by the v0.1 image backend.

Open WebUI mapping:

- Prompt → node `4`, key `text`
- Model → node `1`, key `unet_name`
- Width → node `6`, key `width`
- Height → node `6`, key `height`
- Steps → node `8`, key `steps`
- Seed → node `8`, key `seed`

Do not replace `unet_name` with `ckpt_name`: this workflow uses `UNETLoader`, not `CheckpointLoaderSimple`.
