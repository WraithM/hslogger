{- 
Copyright (C) 2006 John Goerzen <jgoerzen@complete.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-}


module Globtest(tests) where
import Test.HUnit
import MissingH.Path.Glob
import MissingH.Path
import MissingH.HUnit
import MissingH.IO.HVFS
import System.Posix.Directory
import System.Posix.Files
import Control.Exception
import Data.List

bp = "testtmp"
touch x = writeFile x ""

globtest thetest = 
    bracket_ (setupfs)
             (recursiveRemove SystemFS bp)
             thetest
    where setupfs =
              do mapM_ (\x -> createDirectory x 0o755)
                       [bp, bp ++ "/a", bp ++ "/aab", bp ++ "/aaa",
                        bp ++ "/ZZZ", bp ++ "/a/bcd",
                        bp ++ "/a/bcd/efg"]
                 mapM_ touch [bp ++ "/a/D", bp ++ "/aab/F", bp ++ "/aaa/zzzF",
                              bp ++ "/a/bcd/EF", bp ++ "/a/bcd/efg/ha"]
                 createSymbolicLink (preppath "broken") (preppath "sym1")
                 createSymbolicLink (preppath "broken") (preppath "sym2")
                 
eq msg exp res =
    assertEqual msg (sort exp) (sort res)
mf msg func = TestLabel msg $ TestCase $ globtest func
f func = TestCase $ globtest func
preppath x = bp ++ "/" ++ x

test_literal =
    map f
            [glob (preppath "a") >>= eq "" [preppath "a"]
            ,glob (preppath "a/D") >>= eq "" [preppath "a/D"]
            ,glob (preppath "aab") >>= eq "" [preppath "aab"]
            ,glob (preppath "nonexistant") >>= eq "empty" []
            ]

test_one_dir =
    map f
        [glob (preppath "a*") >>= eq "a*" (map preppath ["a", "aab", "aaa"]),
         glob (preppath "*a") >>= eq "*a" (map preppath ["a", "aaa"]),
         glob (preppath "aa?") >>= eq "aa?" (map preppath ["aaa", "aab"]),
         glob (preppath "aa[ab]") >>= eq "aa[ab]" (map preppath ["aaa", "aab"]),
         glob (preppath "*q") >>= eq "*q" []
        ]

test_nested_dir =
    map f
        [glob (preppath "a/bcd/E*") >>= eq "a/bcd/E*" [preppath "a/bcd/EF"],
         glob (preppath "a/bcd/*g") >>= eq "a/bcd/*g" [preppath "a/bcd/efg"]
        ]

test_dirnames = 
    map f
        [glob (preppath "*/D") >>= eq "*/D" [preppath "a/D"],
         glob (preppath "*/*a") >>= eq "*/*a" [],
         glob (preppath "a/*/*/*a") >>= eq "a/*/*/*a" [preppath "a/bcd/efg/ha"],
         glob (preppath "?a?/*F") >>= eq "?a?/*F" (map preppath ["aaa/zzzF", "aab/F"])
        ]

test_brokensymlinks =
    map f
        [glob (preppath "sym*") >>= eq "sym*" (map preppath ["sym1", "sym2"]),
         glob (preppath "sym1") >>= eq "sym1" [preppath "sym1"],
         glob (preppath "sym2") >>= eq "sym2" [preppath "sym2"]
        ]
         

tests = TestList [TestLabel "test_literal" (TestList test_literal),
                  TestLabel "test_one_dir" (TestList test_one_dir),
                  TestLabel "test_nested_dir" (TestList test_nested_dir),
                  TestLabel "test_dirnames" (TestList test_dirnames),
                  TestLabel "test_brokensymlinks" (TestList test_brokensymlinks)]



