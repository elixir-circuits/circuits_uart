# Release checklist

  1. Verify that the regression tests pass for tty0tty on Linux (verified by Travis,
     so this should definitely work)
  2. Verify that the regression tests pass for 2 usb->serial ports connected via
     a NULL modem on Linux and Windows.
  3. Verify that the regression tests pass for 2 usb->serial ports connected via
     a NULL modem on Mac. Serial drivers on the Mac are flakey when being pounded on by
     the regression tests, so running tests individually to see that they pass
     is ok. FTDI drivers work better than Prolific ones.
  4. Update CHANGELOG.md with a bulletpoint list of new features and bug fixes
  5. Run `mix docs` and verify that the docs generate correctly.
  6. Remove the `-dev` from the version numbers in `CHANGELOG.md` and `mix.exs`. If
     doing an `rc` release, mark them appropriately.
  7. For non-rc releases, update the version numbers in `README.md`. They'll be
     incorrect until the release is on hex.pm, but "that's ok".
  8. Run a practice `mix hex.publish`, but don't publish yet. Check for warnings
     and missing files.
  9. Tag
  10. Push last commit(s) *and* tag to GitHub
  11. Wait for the CI builds to complete successfully. They should work
      assuming that no code changes were made between the last build and the tag,
      but wait to be safe.
  12. [SKIP FOR NOW] Copy the circuits_uart.exe artifact created by the Appveyor CI build to `prebuilt/circuits_uart.exe`
  13. Run `mix hex.publish`
  14. Update the deps on a sample project that uses circuits_uart to make sure that it
      downloads and builds the new circuits_uart.
  15. Copy the latest CHANGELOG.md entry to the GitHub releases description.
      Publish the release on GitHub.
  16. Start the next dev cycle. Start a new section in `CHANGELOG.md` and
      update the version in `mix.exs` to a `-dev` version.
  17. Push changes up to GitHub

