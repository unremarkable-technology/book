document.addEventListener('DOMContentLoaded', function () {
	const content = document.querySelector('.content');
	const footer = document.createElement('div');
	footer.style.marginTop = 'auto';
	footer.style.paddingTop = '1rem';
	footer.style.borderTop = '1px solid #ccc';
	footer.style.textAlign = 'center';
	footer.innerHTML = '<a href="/humans.txt">humans.txt</a> | <a href="/LICENSE.txt">licence.txt</a>';
	content.appendChild(footer);

	// Make content area flex to push footer down
	content.style.display = 'flex';
	content.style.flexDirection = 'column';
	content.style.minHeight = '95vh';
});