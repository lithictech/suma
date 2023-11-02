import CloudUploadIcon from "@mui/icons-material/CloudUpload";
import { Button, FormHelperText, FormLabel, Stack, Typography } from "@mui/material";
import React from "react";

function ImageFileInput({ image, onImageChange }) {
  return (
    <Stack spacing={1}>
      <FormLabel>Image:</FormLabel>
      <Button component="label" variant="contained" startIcon={<CloudUploadIcon />}>
        Set image
        <input
          type="file"
          name="image input"
          accept=".jpg,.jpeg,.png"
          hidden
          required
          onChange={(e) => onImageChange(e.target.files[0])}
        />
      </Button>
      <FormHelperText sx={{ mb: 2 }}>
        Use JPEG and PNG formats. Suggest using size 500x500 pixels or above to avoid
        display issues.
      </FormHelperText>
      {Boolean(image) && (
        <>
          <img src={URL.createObjectURL(image)} alt={image.name} />
          <Typography variant="body2">{image.name}</Typography>
        </>
      )}
    </Stack>
  );
}
export default ImageFileInput;
