{!! SeoHelper::render() !!}

@include('plugins/real-estate::themes.dashboard.layouts.header-meta')

<link href="{{ asset('vendor/core/plugins/real-estate/css/dashboard/style.css') }}" rel="stylesheet">

<style>
    @media screen and (max-width: 1199px) {
        .header--mobile .header__center img {
            max-height: 30px !important;
            width: auto;
        }
    }
</style>

@if (session('locale_direction', 'ltr') == 'rtl')
    <link href="{{ asset('vendor/core/core/base/css/core.rtl.css') }}" rel="stylesheet">
    <link href="{{ asset('vendor/core/plugins/real-estate/css/dashboard/style-rtl.css') }}" rel="stylesheet">
@endif

@if (File::exists($styleIntegration = Theme::getStyleIntegrationPath()))
    {!! Html::style(Theme::asset()->url('css/style.integration.css?v=' . filectime($styleIntegration))) !!}
@endif
