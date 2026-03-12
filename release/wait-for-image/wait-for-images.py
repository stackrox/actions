#!/usr/bin/env -S python3 -u

import json
import os
import sys
import time
import urllib.request
from collections import namedtuple
from urllib.parse import urlencode


def main():
    args = parse_args()
    res = check_images(args)
    return 0 if res else 1


def parse_args():
    default_interval = '30'
    default_time_limit = '2400'

    if len(sys.argv) < 2:
        complain("Wait for images to appear in Quay.io.\n"
                 f"Usage: {os.path.basename(sys.argv[0])} <images> [token] [interval] [time-limit]\n"
                 "  images - newline- or whitespace-separated repo names plus tags, e.g. 'rhacs-eng/main:4.10.3 rhacs-eng/roxctl:4.10.3'\n"
                 "  token - optional quay authorization token\n"
                 f"  interval - polling interval in seconds (default: {default_interval})\n"
                 f"  time-limit - maximum duration in seconds to poll (default: {default_time_limit})\n")
        sys.exit(2)

    Image = namedtuple('Image', ['name', 'tag'])
    Result = namedtuple('ParsedArgs', ['images', 'quay_token', 'interval', 'time_limit'])

    def get_arg(i, default):
        return sys.argv[i] if len(sys.argv) > i and sys.argv[i] else default

    images = []
    for img_line in get_arg(1, "").split():
        if img_line:
            name, tag = img_line.split(':', maxsplit=1)
            images.append(Image(name=name, tag=tag))

    if not images:
        raise RuntimeError("No images were provided")

    quay_token = get_arg(2, None)
    interval = int(get_arg(3, default_interval))
    time_limit = int(get_arg(4, default_time_limit))

    return Result(images=images, quay_token=quay_token, interval=interval, time_limit=time_limit)


def complain(message):
    print(message, file=sys.stderr)


def check_images(args):
    images = args.images
    found = [False] * len(images)

    print("Will check the following image(s):")
    for i in range(len(images)):
        print(images[i].name + ':' + images[i].tag)

    start_time = time.time()
    while True:
        for i in range(len(images)):
            if found[i]:
                continue
            found[i] = check_image(images[i], args.quay_token)
            if found[i]:
                print(f"Image '{images[i].name}:{images[i].tag}' has been found.")
            time.sleep(0.1)  # to not fire all request towards Quay.io at once
        all_found = all(found)
        too_late = (time.time() - start_time) > args.time_limit
        if all_found or too_late or args.interval == 0:
            break
        print(f"Waiting {args.interval} more second(s)...")
        time.sleep(args.interval)

    for i in range(len(images)):
        if not found[i]:
            complain(f"Image '{images[i].name}:{images[i].tag}' has not been found.")

    if all_found:
        print("All images have been found.")

    return all_found


def check_image(image, token):
    arg = urlencode([('specificTag', image.tag)])
    req = urllib.request.Request(f"https://quay.io/api/v1/repository/{image.name}/tag?{arg}")
    if token:
        req.add_header('Authorization', f"Bearer {token}")

    try:
        with urllib.request.urlopen(req) as resp:
            body = resp.read().decode('utf-8')
        parsed = json.loads(body)
        return parsed["tags"] and parsed["tags"][0]["name"] == image.tag
    except Exception as e:
        complain(f"Error checking '{image.name}:{image.tag}': {e}")
        return False


if __name__ == '__main__':
    sys.exit(main())
