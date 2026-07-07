# pinned digest for reproducible marketplace action builds
FROM quay.io/ansible/ansible-runner:stable-2.12-latest@sha256:001a4bde411be863d54c1d293f3d2e7b0ff0e67ef5d7b2f9f7fb56b61694f4e8

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
