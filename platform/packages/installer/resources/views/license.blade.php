@extends('packages/installer::layouts.master')

@section('pageTitle', trans('packages/installer::installer.install_step_title', ['step' => 6, 'title' => 'Legacy License Removed']))

@section('header')
    <x-core::card.title>
        Legacy License Removed
    </x-core::card.title>
@endsection

@section('content')
    <form
        id="license-form"
        action="{{ route('installers.licenses.store') }}"
        method="POST"
    >
        @csrf
        <x-core::license.form :reset="false" />
    </form>
@endsection

@section('footer')
    <div class="text-end mt-10">
        <form
            action="{{ route('installers.licenses.skip') }}"
            method="POST"
        >
            @csrf

            <x-core::button
                type="submit"
                color="link"
                size="sm"
            >
                Continue
            </x-core::button>
        </form>
    </div>
@endsection
