module TestMatchesAll
  def test_view_matches_list_signed_in
    get '/matches/all', {}, user_11_session

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match filter form'
    assert_includes last_response.body, 'type="radio"'
    assert_includes last_response.body, 'type="checkbox"'
    assert_includes last_response.body, 'Matches List'
    assert_includes last_response.body, '<td>77</td>'
    assert_includes last_response.body, "<a href=\"/match/48\">View match</a>"
    assert_includes last_response.body, 'Winner Group A'
  end

  def test_view_matches_list_signed_out
    get '/matches/all'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_locked_down_displayed_matches_list
    get '/matches/all', {}, user_11_session

    assert_includes last_response.body.gsub(/\n/, ''), '<td>England</td>          <td>no prediction</td>          <td>no prediction</td>          <td>Iran</td>            <td>Locked down</td>            <td>4</td>            <td>5</td>'
    assert_includes last_response.body.gsub(/\n/, ''), '<td>Qatar</td>          <td>no prediction</td>          <td>no prediction</td>          <td>Ecuador</td>            <td>Locked down</td>            <td>no result</td>            <td>no result</td>          <td>'
    assert_includes last_response.body.gsub(/\n/, ''), '<td>Denmark</td>          <td>71</td>          <td>72</td>          <td>Tunisia</td>            <td>Locked down</td>            <td>no result</td>            <td>no result</td>          <td>'
    assert_includes last_response.body.gsub(/\n/, ''), '<td>Morocco</td>          <td>no prediction</td>          <td>no prediction</td>          <td>Croatia</td>            <td></td>            <td></td>            <td></td>          <td>'
  end

  def test_select_deselect_all_on_match_filter_form
    get '/matches/all', {}, user_11_session

    assert_includes last_response.body, 'Select/Deselect All'
  end
end
