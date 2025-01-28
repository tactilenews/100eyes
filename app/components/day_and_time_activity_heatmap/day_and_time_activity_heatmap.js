import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['heatmap', 'repliesButton', 'requestsButton'];
  static classes = ['active'];
  static values = {
    repliesChartUrl: String,
    requestsChartUrl: String,
  };

  connect() {
    this.renderRepliesHeatmap();
  }

  async fetchData(endpoint) {
    const response = await fetch(endpoint);
    return response.json();
  }

  async fetchHeatmapData(endpoint) {
    const response = await fetch(endpoint);
    const jsonResponse = await response.json();
    const options = this.setupHeatmap(jsonResponse);
    this.renderChart(options);
  }

  setupHeatmap(jsonResponse) {
    const values = jsonResponse.reduce(
      (acc, object) => [...acc, ...Object.values(object.data.map(o => o.y))],
      [],
    );
    const maxValue = Math.max(...values);
    const maxValueDividedByColorSegments = Math.round(maxValue / 6);
    const fontStyles = {
      style: {
        fontSize: '16px',
        fontFamily: 'Inter, Helvetica Neue, Helvetica, sans-serif',
      },
    };

    return {
      chart: {
        type: 'heatmap',
      },
      series: jsonResponse,
      tooltip: {
        custom: function ({ series, seriesIndex, dataPointIndex, w }) {
          return (
            '<div>' +
            '<span>' +
            w.globals.seriesNames[seriesIndex] +
            ', ' +
            w.globals.labels[dataPointIndex].slice(0, 2) +
            '-' +
            (Number(w.globals.labels[dataPointIndex].slice(0, 2)) + 1 == 24
              ? 0
              : Number(w.globals.labels[dataPointIndex].slice(0, 2)) + 1
            ).toLocaleString('de', { minimumIntegerDigits: 2 }) +
            ' Uhr: ' +
            series[seriesIndex][dataPointIndex] +
            ' Interaktionen' +
            '</span>' +
            '</div>'
          );
        },
      },
      xaxis: {
        labels: {
          ...fontStyles,
        },
      },
      yaxis: {
        labels: {
          ...fontStyles,
        },
      },
      legend: {
        ...fontStyles.style,
        position: 'bottom',
        markers: {
          width: 16,
          height: 16,
          radius: 16,
        },
        itemMargin: {
          horizontal: 10,
        },
      },
      plotOptions: {
        heatmap: {
          colorScale: {
            ranges: [
              {
                from: 0,
                to: maxValueDividedByColorSegments,
                color: '#F8C8DC',
                name: 'keine oder geringe',
              },
              {
                from: maxValueDividedByColorSegments + 1,
                to: 2 * maxValueDividedByColorSegments,
                color: '#FFB6C1',
                name: 'kaum',
              },
              {
                from: 2 * maxValueDividedByColorSegments + 1,
                to: 3 * maxValueDividedByColorSegments,
                color: '#FF00A0',
                name: 'mäßige',
              },
              {
                from: 3 * maxValueDividedByColorSegments + 1,
                to: 4 * maxValueDividedByColorSegments,
                color: '#F4177A',
                name: 'mittlere',
              },
              {
                from: 4 * maxValueDividedByColorSegments + 1,
                to: 5 * maxValueDividedByColorSegments,
                color: '#FF1493',
                name: 'starke',
              },
              {
                from: 5 * maxValueDividedByColorSegments + 1,
                to: maxValue,
                color: '#C71585',
                name: 'stärkste Aktivität',
              },
            ],
          },
        },
      },
    };
  }

  renderChart(options) {
    const chart = new window.ApexCharts(this.heatmapTarget, options);
    if (chart) {
      this.heatmapTarget.innerHTML = '';
      chart.render();
    }
  }

  renderRepliesHeatmap() {
    this.requestsButtonTarget.classList.remove(this.activeClass);
    this.repliesButtonTarget.classList.add(this.activeClass);
    this.fetchHeatmapData(this.repliesChartUrlValue);
  }

  renderRequestsHeatmap() {
    this.repliesButtonTarget.classList.remove(this.activeClass);
    this.requestsButtonTarget.classList.add(this.activeClass);
    this.fetchHeatmapData(this.requestsChartUrlValue);
  }
}
