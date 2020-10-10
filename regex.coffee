# Copyright 2014, 2015, 2016, 2017, 2018, 2019 Simon Lydell
# License: MIT. (See LICENSE.)

# <https://tc39.es/ecma262/#sec-lexical-grammar>

# Don’t worry, you don’t need to know CoffeeScript. It is only used for its
# readable regex syntax. Everything else is done in JavaScript in index.js.

module.exports = ///
  ( # <string>
    # 识别字符串以 “'” 、 “"” 开头(gourp 2)
    ([ ' " ])
    (?:
      # 负向零宽先行断言，确保不会再出现开头的内容
      # \\ \n \r 都是字符串中，不允许出现的字符
      (?! \2 )[^ \\ \n \r ]
      |
      # 对转义处理。其中 \r\n 是对续航符中两个字符串情况的处理（一共5中情况，仅\r\n是两个字符）
      \\(?: \r\n | [\s\S] )
    )*
    # 结尾完结
    (\2)?
    |
    # 模板字符串，用 ` 开头
    `
    (?:
      # 与普通字符串类似，因为`确定，所以不用 负向零宽先行断言 了
      [^ ` \\ $ ]
      |
      # 处理转义，优先级比插值高，所以
      \\[\s\S]
      |
      # 处理插值
      \$(?!\{)
      |
      # 插值处理的非常简单
      \$\{
      (?:
        [^{}]
        |
        # 允许有一个成对出现的 {}
        \{ [^}]* \}?
      )*
      \}?
    )*
    # 模板字符串，用 ` 结尾
    (`)?
  )
  |
  ( # <comment>
    # 单行注释很简单
    //.*
  )
  |
  ( # <comment>
    # 多行注释 
    /\*
    (?:
      # 匹配不包含*的内容
      [^*]
      |
      # 匹配含有*的内容
      # 再次使用负向零宽先行断言，与 string 不同点是后面没有内容，因为后面的内容不需要识别。
      \*(?!/)
    )*
    # 必须以 */ 标记结束
    ( \*/ )?
  )
  |
  ( # <regex>
    # 这里有个bug，正则放在注释的后面，有//的内容会被//优先匹配走，如 '/\\\\\\//g+1'.match(regex)
    # 参考 https://tc39.es/ecma262/#prod-RegularExpressionLiteral
    # 开头不能是 *
    /(?!\*)
    (?:
      # RegularExpressionClass
      \[
      (?:
        # ] 和 \ 之外的任意字符
        (?![ \] \\ ]).
        |
        # 转义
        \\.
      )*
      \]
      |
      # / 和 \ 之外的任意字符
      (?![ / \] \\ ]).
      |
      # 任意转义
      \\.
    )+
    # 标记结束
    /
    # flag + 完结判断
    # 不理解为什么要用 负向零宽先行断言 做完结判断，难道是因为对结束标记匹配不准吗？？？？
    (?:
      (?!
        \s*
        (?:
          \b
          |
          [ \u0080-\uFFFF $ \\ ' " ~ ( { ]
          |
          # 字面量不能做左值，所以 负向零宽先行断言 去掉 = 号
          [ + \- ! ](?!=)
          |
          # ？？
          \.?\d
        )
      )
      |
      # 带flag的
      [ g m i y u s ]{1,6} \b
      (?!
        [ \u0080-\uFFFF $ \\ ]
        |
        \s*
        (?:
          [ + \- * % & | ^ < > ! = ? ( { ]
          |
          /(?! [ / * ] )
        )
      )
    )
  )
  |
  ( # <number>
    # 数字字面量，参考 https://tc39.es/ecma262/#sec-literals-numeric-literals
    # 不考虑大整数（bigInteger，新出的，js-token 还未支持） ，则有10进制数、2进制数整数、8进制数整数、16进制数整数，以及科学计数法等几种形式组成
    # 16进制整数
    0[xX][ \d a-f A-F ]+
    |
    # 8进制整数
    0[oO][0-7]+
    |
    # 2进制整数
    0[bB][01]+
    |
    (?:
      \d*\.\d+
      |
      \d+\.? # Support one trailing dot for integers only.
    )
    # 科学计数法
    (?: [eE][+-]?\d+ )?
  )
  |
  ( # <name>
    # See <http://mathiasbynens.be/notes/javascript-identifiers>.
    # 这个 负向零宽先行断言，用的妙，将第一个 IdentifierPart 转成 IdentifierStart。
    (?!\d)
    (?:
      # 去掉 Unicode里面的全角空格符
      (?!\s)[ $ \w \u0080-\uFFFF ]
      |
      # UnicodeEscapeSequence的 u Hex4Digits 形式
      \\u[ \d a-f A-F ]{4}
      |
      # UnicodeEscapeSequence的 u {CodePoint} 形式 
      \\u\{[ \d a-f A-F ]+\}
    )+
  )
  |
  ( # <punctuator>
    # 多字符切不能做赋值操作的操作符
    -- | \+\+
    |
    && | \|\|
    |
    =>
    |
    # ... 符合
    \.{3}
    |
    # 能做赋值运算符
    (?:
      [ + \- / % & | ^ ]
      |
      ## * 和 **
      \*{1,2}
      |
      ## < << > >> >>>，>>>也支持，有点厉害。。。
      <{1,2} | >{1,3}
      |
      !=? | ={1,2}
    # =? 完成了赋值操作符识别，妙呀
    )=?
    |
    # 单字符操作符
    [ ? ~ . , : ; [ \] ( ) { } ]
  )
  |
  ( # <whitespace>
    \s+
  )
  |
  ( # <invalid>
    ^$ # Empty.
    |
    [\s\S] # Catch-all rule for anything not matched by the above.
  )
///g
