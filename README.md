Admin login:
- URL: https://your-domain.com/admin
- Email: admin@company.com
- Password: 12345678

Media storage:

- `RV_MEDIA_DRIVER=local` uses the persistent Docker storage volume.
- `RV_MEDIA_DRIVER=s3` uses Amazon S3 with the `AWS_*` variables documented in `.env.example`.
- Changing the driver does not migrate existing files between local storage and S3.
