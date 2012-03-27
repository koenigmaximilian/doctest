module DocTest (
    getDocTests
  , Example(..)
  , Interaction(..)
  , toTestCase
  , toAssertion
  ) where

import           Test.HUnit (Test(..), assertEqual, Assertion)

import qualified Interpreter
import           Parse
import           Location


toTestCase :: Interpreter.Interpreter -> Module Example -> Test
toTestCase repl (Module name examples) = TestLabel name . TestList . map (TestCase . toAssertion repl name) $ examples

-- |
-- Execute all expressions from given 'Example' in given
-- 'Interpreter.Interpreter' and verify the output.
--
-- The interpreter state is zeroed with @:reload@ before executing the
-- expressions.  This means that you can reuse the same
-- 'Interpreter.Interpreter' for several calls to `toAssertion`.
toAssertion :: Interpreter.Interpreter -> String -> Example -> Assertion
toAssertion repl module_ (Example interactions) = do
  _ <- Interpreter.eval repl $ ":reload"
  _ <- Interpreter.eval repl $ ":m *" ++ module_
  mapM_ interactionToAssertion interactions
  where
    interactionToAssertion (Located loc x) = do
      result' <- Interpreter.eval repl exampleExpression
      assertEqual (show loc ++ ": expression `" ++ exampleExpression ++ "'")
        exampleResult $ lines result'
      where
        exampleExpression = expression x
        exampleResult     = result x
