$(() => {
  $(document).on('click', '[data-modal]', ev => {
    const $tgt = $(ev.target);
    $($tgt.attr('data-modal')).toggleClass('is-active');
  });

  $(document).on('click', '.js-donation-edit', async ev => {
    const $tgt = $(ev.target);
    const $row = $tgt.parents('tr');
    const rowId = $row.attr('data-id');
    const resp = await fetch(`/donations/admin/${rowId}`, {
      credentials: 'include'
    });
    const data = await resp.json();
    $('#name').val(data.name);
    $('#message').val(data.message);
    $('#link').val(data.link);
    $('#date').val(data.date);
    $('#amount').val(data.amount);
    $('#js-edit-modal').attr('data-id', rowId).addClass('is-active');
  });

  $('.js-edit-button').on('click', async ev => {
    const $tgt = $(ev.target);
    const $modal = $tgt.parents('.modal');
    const rowId = $modal.attr('data-id');
    const data = {
      name: $('#name').val(),
      message: $('#message').val(),
      link: $('#link').val(),
      date: $('#date').val(),
      amount: $('#amount').val()
    };

    await fetch(`/donations/admin/${rowId}/edit`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    });
    $modal.removeClass('is-active');

    const cells = $(`tr[data-id="${rowId}"]`).find('td');
    cells.eq(0).text(data.name);
    cells.eq(1).text(data.message);
    cells.eq(2).text(data.date);
    cells.eq(3).text(data.amount);
    cells.eq(4).find('a').eq(0).attr('href', data.link);
  });

  $('.js-new-button').on('click', async ev => {
    const $tgt = $(ev.target);
    const $modal = $tgt.parents('.modal');
    const data = {
      name: $('#new-name').val(),
      message: $('#new-message').val(),
      link: $('#new-link').val(),
      date: $('#new-date').val(),
      amount: $('#new-amount').val()
    };

    const resp = await fetch(`/donations/admin`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    });
    const item = await resp.json();
    $modal.removeClass('is-active');

    const $row = $(`<tr data-id="${item.id}"><td>${item.name}</td><td>${item.message}</td><td>${item.date}</td><td>${item.amount}</td>` +
                   `<td><a href="${item.link}">Link</a><br/>` +
                   `<a href="javascript:void(0)" class="js-donation-edit">Edit</a><br/>` +
                   `<a href="javascript:void(0)" class="js-donation-delete is-red">Delete</a></td></tr>`);
    $row.appendTo('table');
  });

  $(document).on('click', '.js-donation-delete', async ev => {
    const $tgt = $(ev.target);
    const $row = $tgt.parents('tr');
    const rowId = $row.attr('data-id');
    await fetch(`/donations/admin/${rowId}/delete`, {
      method: 'POST',
      credentials: 'include'
    });
    $row.remove();
  });
});