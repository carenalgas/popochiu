from __future__ import unicode_literals
from markdown.extensions import Extension
from markdown.inlinepatterns import InlineProcessor
import xml.etree.ElementTree as etree
from .icon_list import icons
import json
import re

fontawesome_pattern = r':(fa[bsrl]?)?\s?fa-([-\w]+)\s?(fa-(xs|sm|lg|[\d+]x|10x))?:'

prefix_to_style = {
    'fa': 'solid',
    'fas': 'solid',
    'fab': 'brands',
    'far': 'regular',
    'fal': 'light',
}

style_to_prefix = {v: k for k, v in prefix_to_style.items()}


class FontAwesomeException(Exception):
    'Exception for unknown icon name, prefix or size'
    pass


class FontAwesomeInlineProcessor(InlineProcessor):
    'Markdown inline processor class for matching things that look like FA icons'

    def handleMatch(self, m, data):
        el = etree.Element('i')
        prefix = m.group(1)
        icon_name = m.group(2)
        size = m.group(3)
        if icon_name in icons:
            styles = icons[icon_name]
            # if the prefix is not specified, default to 'fa' for solid icons
            if not prefix and 'solid' in styles:
                prefix = 'fa'
            # if the prefix is not specified and the icon has no solid style,
            # default to the first available style
            elif not prefix and 'solid' not in styles:
                style = styles[0]
                prefix = style_to_prefix.get(style)
                if not prefix:
                    # if the first style is not supported, raise an exception
                    raise FontAwesomeException(f"Unknown guessed style {style} for icon {icon_name}")
            # if the specified prefix is not supported, raise an exception
            elif prefix and prefix not in prefix_to_style:
                raise FontAwesomeException(f"Unsupported prefix {prefix}.\nAllowed prefixes are {prefix_to_style.keys()}")
            # if the specified prefix is not available for the icon, raise an exception
            elif prefix and prefix_to_style.get(prefix) not in styles:
                raise FontAwesomeException(f"Prefix 'prefix' is not available for {icon_name}.\nThe icon is available in these styles: {styles}")

            # Everything is fine, set the class attribute
            style = prefix_to_style.get(prefix)
            el.set('class', f'fa-{style} fa-{icon_name} {size}' if size else f'fa-{style} fa-{icon_name}')
            return el, m.start(0), m.end(0)
        else:
            raise FontAwesomeException(f"Unknown icon name: {icon_name}")


class FontAwesomeExtension(Extension):
    def extendMarkdown(self, md):
        md.inlinePatterns.register(FontAwesomeInlineProcessor(fontawesome_pattern, md), 'fontawesome', 175)


def makeExtension(**kwargs):
    return FontAwesomeExtension(**kwargs)